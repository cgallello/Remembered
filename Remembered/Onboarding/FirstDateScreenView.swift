import SwiftUI
import SwiftData
import WidgetKit

struct FirstDateScreenView: View {
    @Environment(\.modelContext) private var modelContext
    var onComplete: () -> Void

    @State private var text = ""
    @State private var placeholder = ""
    @FocusState private var isFocused: Bool
    @AppStorage("lastUsedType") private var lastUsedType: String = "other"

    private let placeholderExamples = [
        "Sam's birthday on Jan 12",
        "Our wedding anniversary October 14",
        "Dad's birthday next Tuesday",
        "Grandma's birthday 8/22"
    ]

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Headline
            Text("Add your first date")
                .font(.title2)
                .fontWeight(.semibold)

            // Subheadline
            Text("Try adding a birthday or any\ndate you want to remember")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            // Input container
            VStack(spacing: 12) {
                // Input field
                ZStack(alignment: .topLeading) {
                    if text.isEmpty {
                        Text(placeholder)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 16)
                            .allowsHitTesting(false)
                    }

                    TextEditor(text: $text)
                        .font(.body)
                        .padding(8)
                        .scrollContentBackground(.hidden)
                        .focused($isFocused)
                        .frame(height: 100)
                }
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)

                // Live type preview (always reserve space to prevent layout shift)
                HStack {
                    Text(!text.isEmpty ? "Will save as: \(currentPredictedType().capitalized)" : " ")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .frame(height: 16)
            }
            .padding(.horizontal, 32)
            .padding(.top, 16)

            Spacer()

            // Save button - disabled until text is entered
            Button(action: saveAndComplete) {
                Text("Save")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
        .onAppear {
            // Set random placeholder
            placeholder = placeholderExamples.randomElement() ?? "Sam's birthday on Jan 12"

            // Auto-focus input after slight delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isFocused = true
            }
        }
    }

    private func currentPredictedType() -> String {
        let result = DateParser.parse(text)
        if result.type != "other" { return result.type }
        return lastUsedType != "other" ? lastUsedType : "other"
    }

    private func saveAndComplete() {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }

        // Dismiss keyboard first
        isFocused = false

        let result = DateParser.parse(trimmedText)

        // Smart Default Logic (same as CaptureView)
        var finalType = result.type
        if finalType == "other" && lastUsedType != "other" {
            finalType = lastUsedType
        }
        lastUsedType = finalType

        let newItem = RememberedItem(
            rawInput: trimmedText,
            title: result.title,
            date: result.date,
            type: finalType,
            needsReview: result.date == nil,
            isNotificationEnabled: StoreManager.shared.isPro
        )

        modelContext.insert(newItem)
        try? modelContext.save()

        // Auto-schedule notifications if Pro
        if StoreManager.shared.isPro {
            Task {
                _ = try? await NotificationManager.shared.requestPermissions()
                NotificationManager.shared.scheduleNotification(for: newItem)
            }
        }

        WidgetCenter.shared.reloadAllTimelines()

        // Track analytics
        AnalyticsManager.track("first_date_added", properties: ["source": "onboarding"])

        // Complete onboarding
        onComplete()
    }
}

#Preview {
    FirstDateScreenView(onComplete: {})
}
