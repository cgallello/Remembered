import SwiftUI
import SwiftData
import WidgetKit

struct CaptureView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var text: String = ""
    @State private var placeholder: String = ""
    @FocusState private var isFocused: Bool
    @AppStorage("lastUsedType") private var lastUsedType: String = "other"
    
    private let placeholderExamples = [
        "Sam's birthday on Jan 12",
        "Our wedding anniversary October 14",
        "Dad's birthday next Tuesday",
        "Mom's memorial on June 15",
        "Grandma's birthday 8/22",
        "Wedding anniversary 10/14"
    ]
    
    var body: some View {
        NavigationStack {
            VStack {
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
                }
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .padding()
                .onAppear {
                    isFocused = true
                    placeholder = placeholderExamples.randomElement() ?? "Sam's birthday on Jan 12"
                }
                
                if !text.isEmpty {
                     let previewType = currentPredictedType()
                     Text("Will save as: \(previewType.capitalized)")
                         .font(.caption)
                         .foregroundStyle(.secondary)
                         .padding(.bottom)
                }
            }
            .navigationTitle("New")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveItem()
                    }
                    .fontWeight(.bold)
                    // Disable save if empty
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private func currentPredictedType() -> String {
        let result = DateParser.parse(text)
        if result.type != "other" { return result.type }
        return lastUsedType != "other" ? lastUsedType : "other"
    }
    
    private func saveItem() {
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
            isNotificationEnabled: StoreManager.shared.isPro // On for Pro, off for free
        )
        
        modelContext.insert(newItem)
        try? modelContext.save() // Force disk save for Widget
        
        // Auto-schedule notifications if Pro
        if StoreManager.shared.isPro {
            Task {
                _ = try? await NotificationManager.shared.requestPermissions()
                NotificationManager.shared.scheduleNotification(for: newItem)
            }
        }
        
        WidgetCenter.shared.reloadAllTimelines()
        dismiss()
    }
}

#Preview {
    CaptureView()
}
