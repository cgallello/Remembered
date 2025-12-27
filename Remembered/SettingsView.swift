import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var items: [RememberedItem]

    @AppStorage("notificationHour") private var notificationHour: Int = 9
    @AppStorage("notificationMinute") private var notificationMinute: Int = 0
    @AppStorage("showDebugFeatures") private var showDebugFeatures: Bool = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = true

    @StateObject private var storeManager = StoreManager.shared
    @State private var showingOnboarding = false
    @State private var showBirthdayImport = false
    
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
                    Button("Sync birthdays from contacts") {
                        showBirthdayImport = true
                    }
                } header: {
                    Text("Contacts")
                } footer: {
                    Text("Import new birthdays or update existing ones from your contacts.")
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

                    Button("Open onboarding") {
                        showingOnboarding = true
                    }
                    .foregroundStyle(.purple)

                    Button("Reset 24hr bday sync limit") {
                        UserDefaults.standard.removeObject(forKey: "lastBirthdaySyncDate")
                    }
                    .foregroundStyle(.purple)
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
        .fullScreenCover(isPresented: $showingOnboarding) {
            OnboardingContainerView()
        }
        .sheet(isPresented: $showBirthdayImport) {
            NavigationStack {
                BirthdayImportView(onContinue: {
                    showBirthdayImport = false
                })
                .navigationTitle("Sync Birthdays")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") {
                            showBirthdayImport = false
                        }
                    }
                }
            }
        }
    }
}
