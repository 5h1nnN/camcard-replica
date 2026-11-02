import Foundation

struct BusinessCardDraft: Equatable, Sendable {
    var ocrRawText: String
    var name: String
    var company: String
    var jobTitle: String
    var mobilePhone: String
    var officePhone: String
    var faxPhone: String
    var email: String
    var website: String
    var address: String
    var notes: String

    nonisolated static let empty = BusinessCardDraft(
        ocrRawText: "",
        name: "",
        company: "",
        jobTitle: "",
        mobilePhone: "",
        officePhone: "",
        faxPhone: "",
        email: "",
        website: "",
        address: "",
        notes: ""
    )

    nonisolated static var fixture: BusinessCardDraft {
        let fixture = FixtureCatalog.syntheticBusinessCard
        return BusinessCardDraft(
            ocrRawText: fixture.rawText,
            name: fixture.name,
            company: fixture.company,
            jobTitle: fixture.jobTitle,
            mobilePhone: fixture.mobilePhone,
            officePhone: fixture.officePhone,
            faxPhone: fixture.faxPhone,
            email: fixture.email,
            website: fixture.website,
            address: fixture.address,
            notes: ""
        )
    }
}
