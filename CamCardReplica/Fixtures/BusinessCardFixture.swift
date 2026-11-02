import Foundation

struct BusinessCardFixture: Equatable, Sendable {
    let rawText: String
    let name: String
    let company: String
    let jobTitle: String
    let mobilePhone: String
    let officePhone: String
    let faxPhone: String
    let email: String
    let website: String
    let address: String
    let assetName: String
}

enum FixtureCatalog {
    nonisolated static let demoID = UUID(uuidString: "4D6C07EA-B880-426C-8C0B-53F1AD17DC06")!

    nonisolated static let syntheticBusinessCard = BusinessCardFixture(
        rawText: """
        示例用户 DEMO USER
        远山创意工作室
        产品设计师 Product Designer
        +86 138 0000 0000
        Office: 021-5555-0102
        Fax: 021-5555-0103
        demo@example.com
        www.example.com
        示例市创新路 88 号
        """,
        name: "示例用户",
        company: "远山创意工作室",
        jobTitle: "产品设计师",
        mobilePhone: "+86 138 0000 0000",
        officePhone: "021-5555-0102",
        faxPhone: "021-5555-0103",
        email: "demo@example.com",
        website: "www.example.com",
        address: "示例市创新路 88 号",
        assetName: "SyntheticBusinessCard"
    )
}
