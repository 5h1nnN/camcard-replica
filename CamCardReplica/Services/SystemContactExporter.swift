import Contacts
import Foundation

enum ContactExportError: LocalizedError {
    case permissionDenied
    case restricted
    case missingIdentity
    case saveFailed(String)

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            "通讯录权限已关闭，请前往系统设置允许访问。"
        case .restricted:
            "此设备限制了通讯录访问，无法导出联系人。"
        case .missingIdentity:
            "请至少填写姓名或公司后再导出。"
        case let .saveFailed(message):
            "系统通讯录保存失败：\(message)"
        }
    }
}

struct ContactExportOutcome: Sendable {
    let identifier: String
    let createdNewContact: Bool
}

enum SystemContactExporter {
    static func export(
        draft: BusinessCardDraft,
        existingIdentifier: String? = nil
    ) async throws -> ContactExportOutcome {
        if ProcessInfo.processInfo.arguments.contains("-UITesting") {
            return ContactExportOutcome(
                identifier: existingIdentifier ?? "UITestContact-\(UUID().uuidString)",
                createdNewContact: existingIdentifier == nil
            )
        }

        let store = CNContactStore()
        try await authorize(store)

        let existingContact = existingIdentifier.flatMap { identifier in
            try? store.unifiedContact(
                withIdentifier: identifier,
                keysToFetch: writableKeys
            )
        }
        let mutableContact: CNMutableContact
        let createdNewContact: Bool

        if let existingContact,
           let mutableCopy = existingContact.mutableCopy() as? CNMutableContact {
            mutableContact = mutableCopy
            createdNewContact = false
        } else {
            mutableContact = CNMutableContact()
            createdNewContact = true
        }

        try populate(mutableContact, from: draft)

        let request = CNSaveRequest()
        request.shouldRefetchContacts = true
        if createdNewContact {
            request.add(mutableContact, toContainerWithIdentifier: nil)
        } else {
            request.update(mutableContact)
        }

        do {
            try store.execute(request)
        } catch {
            throw ContactExportError.saveFailed(error.localizedDescription)
        }

        return ContactExportOutcome(
            identifier: mutableContact.identifier,
            createdNewContact: createdNewContact
        )
    }

    static func makeContact(from draft: BusinessCardDraft) throws -> CNMutableContact {
        let contact = CNMutableContact()
        try populate(contact, from: draft)
        return contact
    }

    private static var writableKeys: [CNKeyDescriptor] {
        [
            CNContactIdentifierKey,
            CNContactTypeKey,
            CNContactGivenNameKey,
            CNContactOrganizationNameKey,
            CNContactJobTitleKey,
            CNContactPhoneNumbersKey,
            CNContactEmailAddressesKey,
            CNContactUrlAddressesKey,
            CNContactPostalAddressesKey
        ].map { $0 as CNKeyDescriptor }
    }

    private static func authorize(_ store: CNContactStore) async throws {
        switch CNContactStore.authorizationStatus(for: .contacts) {
        case .authorized, .limited:
            return
        case .notDetermined:
            do {
                guard try await store.requestAccess(for: .contacts) else {
                    throw ContactExportError.permissionDenied
                }
            } catch let error as ContactExportError {
                throw error
            } catch {
                throw ContactExportError.saveFailed(error.localizedDescription)
            }
        case .denied:
            throw ContactExportError.permissionDenied
        case .restricted:
            throw ContactExportError.restricted
        @unknown default:
            throw ContactExportError.permissionDenied
        }
    }

    private static func populate(
        _ contact: CNMutableContact,
        from draft: BusinessCardDraft
    ) throws {
        let name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let company = draft.company.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty || !company.isEmpty else {
            throw ContactExportError.missingIdentity
        }

        contact.contactType = name.isEmpty ? .organization : .person
        contact.givenName = name
        contact.organizationName = company
        contact.jobTitle = draft.jobTitle.trimmingCharacters(in: .whitespacesAndNewlines)

        contact.phoneNumbers = [
            labeledPhone(draft.mobilePhone, label: CNLabelPhoneNumberMobile),
            labeledPhone(draft.officePhone, label: CNLabelWork)
        ].compactMap { $0 }

        let email = draft.email.trimmingCharacters(in: .whitespacesAndNewlines)
        contact.emailAddresses = email.isEmpty ? [] : [
            CNLabeledValue(label: CNLabelWork, value: email as NSString)
        ]

        let website = draft.website.trimmingCharacters(in: .whitespacesAndNewlines)
        contact.urlAddresses = website.isEmpty ? [] : [
            CNLabeledValue(label: CNLabelWork, value: website as NSString)
        ]

        let address = draft.address.trimmingCharacters(in: .whitespacesAndNewlines)
        if address.isEmpty {
            contact.postalAddresses = []
        } else {
            let postalAddress = CNMutablePostalAddress()
            postalAddress.street = address
            contact.postalAddresses = [
                CNLabeledValue<CNPostalAddress>(label: CNLabelWork, value: postalAddress)
            ]
        }
    }

    private static func labeledPhone(
        _ value: String,
        label: String
    ) -> CNLabeledValue<CNPhoneNumber>? {
        let number = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !number.isEmpty else { return nil }
        return CNLabeledValue(label: label, value: CNPhoneNumber(stringValue: number))
    }
}
