import SwiftUI

struct ChipTextField: View {
    @Binding var text: String
    @Binding var contact: (id: String, name: String)?
    let placeholder: String
    @FocusState.Binding var isFocused: Bool
    let onTextChange: (String) -> Void

    @State private var previousText: String = ""

    var body: some View {
        HStack(spacing: 8) {
            if let contact = contact {
                ContactChip(contactName: contact.name) {
                    // Remove contact
                    self.contact = nil
                }
            }

            TextField(placeholder, text: $text, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...3)
                .focused($isFocused)
                .onChange(of: text) { oldValue, newValue in
                    handleTextChange(oldValue: oldValue, newValue: newValue)
                    onTextChange(newValue)
                }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(20)
    }

    private func handleTextChange(oldValue: String, newValue: String) {
        // Detect backspace when field becomes empty and was already empty
        // This means user pressed backspace with no text, so delete the chip
        if newValue.isEmpty && oldValue.isEmpty && contact != nil {
            contact = nil
        }
    }
}

#Preview {
    @Previewable @State var text = ""
    @Previewable @State var contact: (id: String, name: String)? = ("123", "Stef")
    @Previewable @FocusState var isFocused: Bool

    VStack(spacing: 20) {
        Text("With Contact:")
        ChipTextField(
            text: $text,
            contact: $contact,
            placeholder: "Add a date...",
            isFocused: $isFocused,
            onTextChange: { _ in }
        )

        Text("Without Contact:")
        ChipTextField(
            text: $text,
            contact: .constant(nil),
            placeholder: "Add a date...",
            isFocused: $isFocused,
            onTextChange: { _ in }
        )

        Text("Contact: \(contact?.name ?? "none")")
        Text("Text: \(text)")

        Button("Set Contact") {
            contact = ("456", "Chris")
        }

        Button("Clear Contact") {
            contact = nil
        }
    }
    .padding()
}
