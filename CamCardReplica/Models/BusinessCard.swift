import Foundation
import SwiftData

@Model
final class BusinessCard {
    @Attribute(.unique) var id: UUID
    var originalImagePath: String?
    var ocrRawText: String
    var name: String
    var company: String
    var jobTitle: String
    var mobilePhone: String
    var officePhone: String
    var email: String
    var website: String
    var address: String
    var notes: String
    var isFavorite: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        originalImagePath: String? = nil,
        draft: BusinessCardDraft,
        isFavorite: Bool = false,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.originalImagePath = originalImagePath
        self.ocrRawText = draft.ocrRawText
        self.name = draft.name
        self.company = draft.company
        self.jobTitle = draft.jobTitle
        self.mobilePhone = draft.mobilePhone
        self.officePhone = draft.officePhone
        self.email = draft.email
        self.website = draft.website
        self.address = draft.address
        self.notes = draft.notes
        self.isFavorite = isFavorite
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var draft: BusinessCardDraft {
        BusinessCardDraft(
            ocrRawText: ocrRawText,
            name: name,
            company: company,
            jobTitle: jobTitle,
            mobilePhone: mobilePhone,
            officePhone: officePhone,
            email: email,
            website: website,
            address: address,
            notes: notes
        )
    }

    func apply(_ draft: BusinessCardDraft, updatedAt: Date = .now) {
        ocrRawText = draft.ocrRawText
        name = draft.name
        company = draft.company
        jobTitle = draft.jobTitle
        mobilePhone = draft.mobilePhone
        officePhone = draft.officePhone
        email = draft.email
        website = draft.website
        address = draft.address
        notes = draft.notes
        self.updatedAt = updatedAt
    }

    func matches(_ query: String) -> Bool {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else { return true }
        return [name, company, jobTitle, mobilePhone, officePhone, email]
            .contains { $0.localizedCaseInsensitiveContains(needle) }
    }
}
