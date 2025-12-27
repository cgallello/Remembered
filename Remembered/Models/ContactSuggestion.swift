import Foundation

struct ContactSuggestion: Identifiable {
    let id: String              // CNContact identifier
    let displayName: String     // Full name
    let givenName: String
    let familyName: String
}

struct ContactBirthday: Identifiable {
    let id: String
    let name: String
    let birthday: DateComponents
    var isSelected: Bool
}
