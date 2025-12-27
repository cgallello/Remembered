import Foundation
import Contacts

class ContactManager {
    static let shared = ContactManager()
    private let contactStore = CNContactStore()

    // Cache for performance
    private var cachedContacts: [CNContact] = []
    private var cacheTimestamp: Date?
    private let cacheTimeout: TimeInterval = 300 // 5 minutes

    private init() {}

    // MARK: - Permission Management

    func requestPermission() async -> Bool {
        do {
            return try await contactStore.requestAccess(for: .contacts)
        } catch {
            print("Contact permission request failed: \(error)")
            return false
        }
    }

    func checkPermissionStatus() -> CNAuthorizationStatus {
        return CNContactStore.authorizationStatus(for: .contacts)
    }

    var permissionGranted: Bool {
        return checkPermissionStatus() == .authorized
    }

    // MARK: - Contact Searching (for real-time tagging)

    func searchContacts(matching token: String) -> [ContactSuggestion] {
        guard permissionGranted else { return [] }
        guard token.count >= 3 else { return [] }

        let contacts = getAllContacts()
        let lowercaseToken = token.lowercased()

        var matches: [(contact: CNContact, score: Int)] = []

        for contact in contacts {
            let givenName = contact.givenName.lowercased()
            let familyName = contact.familyName.lowercased()
            let fullName = "\(contact.givenName) \(contact.familyName)".lowercased()

            var score = 0

            // Prefix match on given name (highest priority)
            if givenName.hasPrefix(lowercaseToken) {
                score = 100
            }
            // Prefix match on full display name
            else if fullName.hasPrefix(lowercaseToken) {
                score = 95
            }
            // Prefix match on family name
            else if familyName.hasPrefix(lowercaseToken) {
                score = 80
            }
            // Contains match (only if token >= 5 chars)
            else if lowercaseToken.count >= 5 {
                if givenName.contains(lowercaseToken) || familyName.contains(lowercaseToken) {
                    score = 50
                }
            }

            if score > 0 {
                matches.append((contact, score))
            }
        }

        // Sort by score descending, take top 3
        return matches
            .sorted { $0.score > $1.score }
            .prefix(3)
            .map { ContactSuggestion(from: $0.contact) }
    }

    // MARK: - Birthday Fetching (for import)

    func fetchContactsWithBirthdays() -> [ContactBirthday] {
        guard permissionGranted else { return [] }

        let contacts = getAllContacts()

        return contacts
            .compactMap { contact -> ContactBirthday? in
                guard let birthday = contact.birthday else { return nil }

                let displayName = CNContactFormatter.string(from: contact, style: .fullName) ?? "\(contact.givenName) \(contact.familyName)"

                return ContactBirthday(
                    id: contact.identifier,
                    name: displayName,
                    birthday: birthday,
                    isSelected: true
                )
            }
            .sorted { $0.name < $1.name }
    }

    // MARK: - Individual Contact Lookup

    func getContact(id: String) -> CNContact? {
        guard permissionGranted else { return nil }

        let keysToFetch = [
            CNContactGivenNameKey,
            CNContactFamilyNameKey,
            CNContactBirthdayKey,
            CNContactFormatter.descriptorForRequiredKeys(for: .fullName)
        ] as [Any]

        do {
            return try contactStore.unifiedContact(withIdentifier: id, keysToFetch: keysToFetch as! [CNKeyDescriptor])
        } catch {
            return nil
        }
    }

    func validateContactExists(id: String) -> Bool {
        return getContact(id: id) != nil
    }

    // MARK: - Contact Update Sync

    func syncBirthdayForContact(id: String) -> DateComponents? {
        guard let contact = getContact(id: id) else { return nil }
        return contact.birthday
    }

    func clearCache() {
        cachedContacts = []
        cacheTimestamp = nil
    }

    // MARK: - Contact Birthday Update

    func updateContactBirthday(contactId: String, birthday: Date) -> Result<Void, Error> {
        guard permissionGranted else {
            return .failure(NSError(domain: "ContactManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "No contacts permission"]))
        }

        // Fetch the contact
        guard let contact = getContact(id: contactId) else {
            return .failure(NSError(domain: "ContactManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "Contact not found"]))
        }

        // Create mutable copy
        let mutableContact = contact.mutableCopy() as! CNMutableContact

        // Convert Date to DateComponents (no year for birthdays)
        let calendar = Calendar.current
        var components = calendar.dateComponents([.month, .day], from: birthday)
        components.calendar = calendar

        // Set birthday
        mutableContact.birthday = components

        // Save the contact
        let saveRequest = CNSaveRequest()
        saveRequest.update(mutableContact)

        do {
            try contactStore.execute(saveRequest)
            // Clear cache to refresh
            clearCache()
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    func getContactBirthday(contactId: String) -> DateComponents? {
        guard let contact = getContact(id: contactId) else { return nil }
        return contact.birthday
    }

    // MARK: - Private Helpers

    private func getAllContacts() -> [CNContact] {
        // Check cache
        if !cachedContacts.isEmpty,
           let timestamp = cacheTimestamp,
           Date().timeIntervalSince(timestamp) < cacheTimeout {
            return cachedContacts
        }

        // Fetch fresh contacts
        let keysToFetch = [
            CNContactGivenNameKey,
            CNContactFamilyNameKey,
            CNContactNicknameKey,
            CNContactBirthdayKey,
            CNContactFormatter.descriptorForRequiredKeys(for: .fullName)
        ] as [Any]

        let request = CNContactFetchRequest(keysToFetch: keysToFetch as! [CNKeyDescriptor])

        var contacts: [CNContact] = []

        do {
            try contactStore.enumerateContacts(with: request) { contact, _ in
                contacts.append(contact)
            }

            // Update cache
            cachedContacts = contacts
            cacheTimestamp = Date()

        } catch {
            print("Failed to fetch contacts: \(error)")
        }

        return contacts
    }
}

// MARK: - ContactSuggestion Extension

extension ContactSuggestion {
    init(from contact: CNContact) {
        let displayName = CNContactFormatter.string(from: contact, style: .fullName) ?? "\(contact.givenName) \(contact.familyName)"

        self.init(
            id: contact.identifier,
            displayName: displayName,
            givenName: contact.givenName,
            familyName: contact.familyName
        )
    }
}
