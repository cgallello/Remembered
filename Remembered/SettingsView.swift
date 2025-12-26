import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var items: [RememberedItem]
    
    @AppStorage("notificationHour") private var notificationHour: Int = 9
    @AppStorage("notificationMinute") private var notificationMinute: Int = 0
    @AppStorage("showDebugFeatures") private var showDebugFeatures: Bool = false
    
    @StateObject private var storeManager = StoreManager.shared
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Reminders") {
                    DatePicker("Notification Time", selection: Binding(
                        get: {
                            var components = DateComponents()
                            components.hour = notificationHour
                            components.minute = notificationMinute
                            return Calendar.current.date(from: components) ?? Date()
                        },
                        set: { newDate in
                            let components = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                            notificationHour = components.hour ?? 9
                            notificationMinute = components.minute ?? 0
                            
                            // Reschedule all when time changes
                            NotificationManager.shared.rescheduleAllNotifications(items: items)
                        }
                    ), displayedComponents: .hourAndMinute)
                }
                
                Section {
                    Toggle("Debug: Pro Status", isOn: Binding(
                        get: { storeManager.isPro },
                        set: { _ in
                            storeManager.debugTogglePro()
                        }
                    ))
                    .tint(.purple)
                    
                    Toggle("Debug: Show Reference Section", isOn: $showDebugFeatures)
                        .tint(.purple)
                } header: {
                    Text("Debug")
                }
                
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
