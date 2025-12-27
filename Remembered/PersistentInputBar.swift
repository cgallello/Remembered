import SwiftUI
import SwiftData
import WidgetKit

struct PersistentInputBar: View {
    @Environment(\.modelContext) private var modelContext

    @Binding var preFillText: String
    var shouldFocus: Bool

    @State private var inputText = ""
    @FocusState private var isFocused: Bool
    @AppStorage("lastUsedType") private var lastUsedType: String = "other"

    // Contact tagging state
    @State private var selectedContact: (id: String, name: String)? = nil
    @State private var suggestions: [ContactSuggestion] = []

    // Birthday conflict state
    @State private var showBirthdayConflict = false
    @State private var pendingBirthdayUpdate: (contactId: String, newBirthday: Date, existingBirthday: DateComponents)? = nil

    var body: some View {
        VStack(spacing: 8) {
            Divider()

            // Live type preview
            if !inputText.isEmpty {
                let result = DateParser.parse(inputText)
                let typeEmoji = icon(for: result.type)
                HStack {
                    Text("\(typeEmoji) \(result.type.capitalized)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal)
            }

            // Contact suggestion strip (only show if no contact selected yet)
            if !suggestions.isEmpty && ContactManager.shared.permissionGranted && selectedContact == nil {
                ContactSuggestionStrip(suggestions: suggestions) { suggestion in
                    handleContactSelection(suggestion)
                }
            }

            // Input + send button
            HStack(spacing: 12) {
                ChipTextField(
                    text: $inputText,
                    contact: $selectedContact,
                    placeholder: "Add a date...",
                    isFocused: $isFocused,
                    onTextChange: { newText in
                        updateSuggestions(for: newText)
                    }
                )
                .onChange(of: preFillText) { oldValue, newValue in
                    if !newValue.isEmpty {
                        inputText = newValue
                        isFocused = true
                    }
                }
                .onChange(of: shouldFocus) { oldValue, newValue in
                    if newValue {
                        isFocused = true
                    }
                }

                if !inputText.trimmingCharacters(in: .whitespaces).isEmpty {
                    Button(action: saveAndClear) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.blue)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .background(Color(.systemBackground))
        .animation(.easeInOut(duration: 0.2), value: inputText.isEmpty)
        .confirmationDialog(
            "Update Contact Birthday?",
            isPresented: $showBirthdayConflict,
            presenting: pendingBirthdayUpdate
        ) { update in
            Button("Update to \(formatDate(update.newBirthday))") {
                confirmBirthdayUpdate()
            }
            Button("Keep \(formatDateComponents(update.existingBirthday))") {
                pendingBirthdayUpdate = nil
            }
            Button("Cancel", role: .cancel) {
                pendingBirthdayUpdate = nil
            }
        } message: { update in
            Text("This contact already has a birthday set to \(formatDateComponents(update.existingBirthday)). Do you want to update it to \(formatDate(update.newBirthday))?")
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        return formatter.string(from: date)
    }

    private func formatDateComponents(_ components: DateComponents) -> String {
        guard let month = components.month, let day = components.day else {
            return "unknown"
        }
        let calendar = Calendar.current
        var dateComponents = DateComponents()
        dateComponents.month = month
        dateComponents.day = day
        dateComponents.year = 2000 // Arbitrary year for formatting
        guard let date = calendar.date(from: dateComponents) else {
            return "\(month)/\(day)"
        }
        return formatDate(date)
    }

    private func saveAndClear() {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty || selectedContact != nil else { return }

        // Include contact name in the text for parsing if contact is selected
        let fullText = selectedContact != nil ? "\(selectedContact!.name) \(text)" : text
        let result = DateParser.parse(fullText)

        // Smart Default Logic:
        // 1. If parser found a specific type (e.g. "birthday"), use it.
        // 2. If parser found "other", fallback to the last used type (sticky session).
        var finalType = result.type
        if finalType == "other" && lastUsedType != "other" {
            finalType = lastUsedType
        }

        // Update sticky default
        lastUsedType = finalType

        // Use contact name as title if selected, otherwise use parsed title
        let finalTitle = selectedContact?.name ?? result.title

        let newItem = RememberedItem(
            rawInput: fullText,
            title: finalTitle,
            date: result.date,
            type: finalType,
            needsReview: result.date == nil,
            isNotificationEnabled: StoreManager.shared.isPro,
            contactId: selectedContact?.id,
            contactDisplayName: selectedContact?.name
        )

        modelContext.insert(newItem)
        try? modelContext.save()

        // Haptic feedback for successful save
        HapticManager.success()

        // Auto-schedule notifications if Pro
        if StoreManager.shared.isPro {
            Task {
                _ = try? await NotificationManager.shared.requestPermissions()
                NotificationManager.shared.scheduleNotification(for: newItem)
            }
        }

        WidgetCenter.shared.reloadAllTimelines()

        // Check if we should update contact birthday
        checkAndUpdateContactBirthday(contactId: selectedContact?.id, type: finalType, date: result.date)

        // Clear input
        inputText = ""
        preFillText = ""
        selectedContact = nil
        suggestions = []
    }

    private func checkAndUpdateContactBirthday(contactId: String?, type: String, date: Date?) {
        // Only update if it's a birthday with a contact linked
        guard type == "birthday",
              let contactId = contactId,
              let newBirthday = date,
              ContactManager.shared.permissionGranted else {
            return
        }

        // Check if contact already has a birthday
        if let existingBirthday = ContactManager.shared.getContactBirthday(contactId: contactId) {
            // Compare birthdays (month and day only)
            let calendar = Calendar.current
            let newComponents = calendar.dateComponents([.month, .day], from: newBirthday)

            if existingBirthday.month != newComponents.month || existingBirthday.day != newComponents.day {
                // Conflict! Ask user
                pendingBirthdayUpdate = (contactId, newBirthday, existingBirthday)
                showBirthdayConflict = true
            }
            // If same birthday, do nothing
        } else {
            // No existing birthday, set it
            _ = ContactManager.shared.updateContactBirthday(contactId: contactId, birthday: newBirthday)
        }
    }

    private func confirmBirthdayUpdate() {
        guard let update = pendingBirthdayUpdate else { return }
        _ = ContactManager.shared.updateContactBirthday(contactId: update.contactId, birthday: update.newBirthday)
        pendingBirthdayUpdate = nil
    }

    // MARK: - Contact Tagging Helpers

    private func extractActiveToken(from text: String) -> String {
        let delimiters: Set<Character> = [" ", ",", ".", "\n"]
        if let lastIndex = text.lastIndex(where: { delimiters.contains($0) }) {
            return String(text[text.index(after: lastIndex)...])
        }
        return text
    }

    private func updateSuggestions(for text: String) {
        // Don't show suggestions if contact already selected
        guard selectedContact == nil else {
            suggestions = []
            return
        }

        let token = extractActiveToken(from: text)

        guard token.count >= 3 else {
            suggestions = []
            return
        }

        suggestions = ContactManager.shared.searchContacts(matching: token)
    }

    private func handleContactSelection(_ suggestion: ContactSuggestion) {
        // Set selected contact
        selectedContact = (id: suggestion.id, name: suggestion.displayName)

        // Remove the active token from text (chip will show contact instead)
        let token = extractActiveToken(from: inputText)
        if let range = inputText.range(of: token, options: .backwards) {
            inputText.replaceSubrange(range, with: "")
        }

        // Clear suggestions
        suggestions = []

        // Keep keyboard open, cursor at end
        isFocused = true
    }

    private func icon(for type: String) -> String {
        switch type {
        case "birthday": return "🎂"
        case "anniversary": return "💍"
        case "medical": return "🏥"
        case "memorial": return "🕯️"
        default: return "🗓️"
        }
    }
}

#Preview {
    @Previewable @State var preFillText = ""

    PersistentInputBar(preFillText: $preFillText, shouldFocus: false)
        .modelContainer(for: RememberedItem.self, inMemory: true)
}
