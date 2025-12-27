import SwiftUI

struct ContactSuggestionStrip: View {
    let suggestions: [ContactSuggestion]
    let onSelect: (ContactSuggestion) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(suggestions) { suggestion in
                    Button(action: { onSelect(suggestion) }) {
                        Text(suggestion.displayName)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color(.tertiarySystemFill))
                            .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        Text("3 Suggestions:")
        ContactSuggestionStrip(
            suggestions: [
                ContactSuggestion(id: "1", displayName: "Stef", givenName: "Stef", familyName: ""),
                ContactSuggestion(id: "2", displayName: "Chris", givenName: "Chris", familyName: "Anderson"),
                ContactSuggestion(id: "3", displayName: "Sam", givenName: "Sam", familyName: "Smith")
            ],
            onSelect: { suggestion in
                print("Selected: \(suggestion.displayName)")
            }
        )

        Text("1 Suggestion:")
        ContactSuggestionStrip(
            suggestions: [
                ContactSuggestion(id: "1", displayName: "Stef", givenName: "Stef", familyName: "")
            ],
            onSelect: { suggestion in
                print("Selected: \(suggestion.displayName)")
            }
        )

        Text("Long Names:")
        ContactSuggestionStrip(
            suggestions: [
                ContactSuggestion(id: "1", displayName: "Christopher Anderson", givenName: "Christopher", familyName: "Anderson"),
                ContactSuggestion(id: "2", displayName: "Samantha Rodriguez", givenName: "Samantha", familyName: "Rodriguez"),
                ContactSuggestion(id: "3", displayName: "Alexander Thompson", givenName: "Alexander", familyName: "Thompson")
            ],
            onSelect: { suggestion in
                print("Selected: \(suggestion.displayName)")
            }
        )
    }
}
