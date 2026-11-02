import Foundation
import SwiftData

enum CardGroupStoreError: LocalizedError, Equatable {
    case emptyName
    case duplicateName
    case missingGroup

    var errorDescription: String? {
        switch self {
        case .emptyName:
            "分组名称不能为空。"
        case .duplicateName:
            "已经存在同名分组。"
        case .missingGroup:
            "分组已不存在，请刷新后重试。"
        }
    }
}

@MainActor
enum CardGroupStore {
    static func create(
        name: String,
        groups: [CardGroup],
        in context: ModelContext,
        now: Date = .now
    ) throws -> CardGroup {
        let cleanName = normalizedName(name)
        guard !cleanName.isEmpty else { throw CardGroupStoreError.emptyName }
        guard !contains(name: cleanName, excluding: nil, in: groups) else {
            throw CardGroupStoreError.duplicateName
        }

        let group = CardGroup(
            name: cleanName,
            createdAt: now,
            updatedAt: now,
            sortOrder: (groups.map(\.sortOrder).max() ?? -1) + 1
        )
        context.insert(group)
        try context.save()
        return group
    }

    static func rename(
        _ group: CardGroup,
        to name: String,
        groups: [CardGroup],
        in context: ModelContext,
        now: Date = .now
    ) throws {
        let cleanName = normalizedName(name)
        guard !cleanName.isEmpty else { throw CardGroupStoreError.emptyName }
        guard !contains(name: cleanName, excluding: group.id, in: groups) else {
            throw CardGroupStoreError.duplicateName
        }
        group.name = cleanName
        group.updatedAt = now
        try context.save()
    }

    static func delete(
        _ group: CardGroup,
        cards: [BusinessCard],
        in context: ModelContext
    ) throws {
        for card in cards where card.groupIDs.contains(group.id) {
            card.groupIDs.removeAll { $0 == group.id }
            card.updatedAt = .now
        }
        context.delete(group)
        try context.save()
    }

    static func setGroups(
        _ groupIDs: Set<UUID>,
        for card: BusinessCard,
        availableGroups: [CardGroup],
        in context: ModelContext,
        now: Date = .now
    ) throws {
        let availableIDs = Set(availableGroups.map(\.id))
        card.groupIDs = groupIDs
            .intersection(availableIDs)
            .sorted { $0.uuidString < $1.uuidString }
        card.updatedAt = now
        try context.save()
    }

    static func groupNames(for card: BusinessCard, groups: [CardGroup]) -> [String] {
        let namesByID = Dictionary(uniqueKeysWithValues: groups.map { ($0.id, $0.name) })
        return card.groupIDs.compactMap { namesByID[$0] }.sorted()
    }

    private static func contains(name: String, excluding id: UUID?, in groups: [CardGroup]) -> Bool {
        groups.contains { group in
            group.id != id && group.name.compare(
                name,
                options: [.caseInsensitive, .diacriticInsensitive],
                range: nil,
                locale: .current
            ) == .orderedSame
        }
    }

    private static func normalizedName(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
