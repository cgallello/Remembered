import SwiftUI
import SwiftData
import WidgetKit

struct DetailView: View {
    @Bindable var item: RememberedItem
    @Environment(\.dismiss) private var dismiss
    @AppStorage("showDebugFeatures") private var showDebugFeatures: Bool = false
    
    var body: some View {
        Form {
            Section("Details") {
                TextField("Title", text: $item.title)
                
                if let date = item.date {
                    DatePicker("Date", selection: Binding(
                        get: { date },
                        set: { item.date = $0 }
                    ), displayedComponents: .date)
                        .onChange(of: item.date) {
                            try? item.modelContext?.save()
                            WidgetCenter.shared.reloadAllTimelines()
                        }
                } else {
                    Button("Add Date") {
                        // Set to next year instead of today
                        let calendar = Calendar.current
                        if let nextYear = calendar.date(byAdding: .year, value: 1, to: Date()) {
                            item.date = nextYear
                        } else {
                            item.date = Date()
                        }
                    }
                }
                
                Picker("Type", selection: $item.type) {
                    Text("Birthday").tag("birthday")
                    Text("Anniversary").tag("anniversary")
                    Text("Medical").tag("medical")
                    Text("Memorial").tag("memorial")
                    Text("Other").tag("other")
                }
                .onChange(of: item.title) {
                    try? item.modelContext?.save()
                    WidgetCenter.shared.reloadAllTimelines()
                }
                .onChange(of: item.type) {
                    try? item.modelContext?.save()
                    WidgetCenter.shared.reloadAllTimelines()
                }
            }
            
            Section("Notifications") {
                Toggle("Enabled", isOn: Binding(
                    get: { item.isNotificationEnabled },
                    set: { newValue in
                        if newValue {
                            if StoreManager.shared.isPro {
                                Task {
                                    let granted = try? await NotificationManager.shared.requestPermissions()
                                    if granted == true {
                                        item.isNotificationEnabled = true
                                        NotificationManager.shared.scheduleNotification(for: item)
                                    } else {
                                        item.isNotificationEnabled = false
                                    }
                                }
                            } else {
                                showingPaywall = true
                            }
                        } else {
                            item.isNotificationEnabled = false
                            NotificationManager.shared.cancelNotification(for: item)
                        }
                    }
                ))
                
                if item.isNotificationEnabled {
                    let intervals = [
                        ("1 month before", "oneMonth"),
                        ("2 weeks before", "twoWeeks"),
                        ("1 week before", "oneWeek"),
                        ("3 days before", "threeDays"),
                        ("1 day before", "oneDay"),
                        ("Day of", "dayOf")
                    ]
                    
                    ForEach(intervals, id: \.1) { label, value in
                        Toggle(label, isOn: Binding(
                            get: { item.notificationIntervals.contains(value) },
                            set: { isSelected in
                                if isSelected {
                                    if !item.notificationIntervals.contains(value) {
                                        item.notificationIntervals.append(value)
                                    }
                                } else {
                                    item.notificationIntervals.removeAll { $0 == value }
                                }
                                NotificationManager.shared.scheduleNotification(for: item)
                            }
                        ))
                    }
                }
            }
            
            Section("Notes") {
                TextEditor(text: $item.notes)
                    .frame(minHeight: 100)
            }
            
            if showDebugFeatures {
                Section("Reference") {
                    LabeledContent("Raw Input", value: item.rawInput)
                    LabeledContent("Created", value: item.createdAt.formatted())
                    
                    Button("Debug: Print Pending Notifications") {
                        NotificationManager.shared.printPendingNotifications()
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Date")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
    }
    
    @State private var showingPaywall = false
}
