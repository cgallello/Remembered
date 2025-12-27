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

            // Input + send button
            HStack(spacing: 12) {
                TextField("Add a date...", text: $inputText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(1...3)
                    .padding(12)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(20)
                    .focused($isFocused)
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
    }

    private func saveAndClear() {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }

        let result = DateParser.parse(text)

        // Smart Default Logic:
        // 1. If parser found a specific type (e.g. "birthday"), use it.
        // 2. If parser found "other", fallback to the last used type (sticky session).
        var finalType = result.type
        if finalType == "other" && lastUsedType != "other" {
            finalType = lastUsedType
        }

        // Update sticky default
        lastUsedType = finalType

        let newItem = RememberedItem(
            rawInput: text,
            title: result.title,
            date: result.date,
            type: finalType,
            needsReview: result.date == nil,
            isNotificationEnabled: StoreManager.shared.isPro
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

        // Clear input
        inputText = ""
        preFillText = ""
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
