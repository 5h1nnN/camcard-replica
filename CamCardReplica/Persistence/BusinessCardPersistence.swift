import Foundation
import SwiftData

enum BusinessCardPersistenceError: LocalizedError {
    case recordNotFound

    var errorDescription: String? {
        switch self {
        case .recordNotFound:
            "这张名片已不存在，请返回名片夹刷新。"
        }
    }
}

@MainActor
enum BusinessCardPersistence {
    static func save(
        draft: BusinessCardDraft,
        imageData: Data?,
        editingCardID: UUID?,
        in context: ModelContext,
        imageStore: CardImageStore = .live,
        now: Date = .now
    ) throws -> BusinessCard {
        if let editingCardID {
            let descriptor = FetchDescriptor<BusinessCard>(
                predicate: #Predicate { $0.id == editingCardID }
            )
            guard let card = try context.fetch(descriptor).first else {
                throw BusinessCardPersistenceError.recordNotFound
            }

            var newImagePath: String?
            if card.originalImagePath == nil, let imageData {
                newImagePath = try imageStore.save(imageData, for: card.id)
                card.originalImagePath = newImagePath
            }
            card.apply(draft, updatedAt: now)

            do {
                try context.save()
                return card
            } catch {
                context.rollback()
                if let newImagePath {
                    try? imageStore.delete(relativePath: newImagePath)
                }
                throw error
            }
        }

        let id = UUID()
        var imagePath: String?
        if let imageData {
            imagePath = try imageStore.save(imageData, for: id)
        }

        let card = BusinessCard(
            id: id,
            originalImagePath: imagePath,
            draft: draft,
            createdAt: now,
            updatedAt: now
        )
        context.insert(card)

        do {
            try context.save()
            return card
        } catch {
            context.rollback()
            if let imagePath {
                try? imageStore.delete(relativePath: imagePath)
            }
            throw error
        }
    }

    static func delete(
        _ card: BusinessCard,
        in context: ModelContext,
        imageStore: CardImageStore = .live
    ) throws {
        let imagePath = card.originalImagePath
        context.delete(card)
        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
        // The record is the source of truth. A file-system cleanup failure must not
        // resurrect a deleted card or leave the UI pointing at a removed model.
        try? imageStore.delete(relativePath: imagePath)
    }
}
