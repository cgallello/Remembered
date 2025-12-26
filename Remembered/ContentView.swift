import SwiftUI
import SwiftData
import WidgetKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RememberedItem.date) private var items: [RememberedItem]

    @State private var showingSettingsSheet = false
    @State private var showingPaywall = false
    @State private var preFillText: String = ""
    @State private var keyboardHeight: CGFloat = 0
    @State private var triggerFocus = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Main content
                if items.isEmpty {
                    EmptyStateView(
                        onExampleTapped: { example in
                            preFillText = example
                            triggerFocus = true
                            // Reset for next time
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                triggerFocus = false
                            }
                        },
                        onAddTapped: {
                            preFillText = ""
                            triggerFocus = true
                            // Reset for next time
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                triggerFocus = false
                            }
                        }
                    )
                } else {
                    List {
                        ForEach(items) { item in
                            NavigationLink(destination: DetailView(item: item)) {
                                HStack(spacing: 12) {
                                    Text(icon(for: item.type))
                                        .font(.title2)
                                        .frame(width: 32)

                                    VStack(alignment: .leading) {
                                        Text(item.title)
                                            .font(.headline)
                                    }

                                    Spacer()

                                    VStack(alignment: .trailing) {
                                        if let date = item.date {
                                            Text(date.formatted(.dateTime.month().day()))
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                                .foregroundStyle(.secondary)
                                        }

                                        if let days = item.daysUntil, days <= 60 {
                                            Text(item.countdownString)
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }

                                        if item.needsReview {
                                            Image(systemName: "exclamationmark.triangle.fill")
                                                .font(.caption2)
                                                .foregroundColor(.orange)
                                        }
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .onDelete(perform: deleteItems)
                    }
                }

                // Input bar - always at bottom of VStack
                PersistentInputBar(preFillText: $preFillText, shouldFocus: triggerFocus)
            }
            .navigationTitle("Dates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingSettingsSheet = true }) {
                        Label("Settings", systemImage: "gear")
                    }
                }
            }
            .sheet(isPresented: $showingSettingsSheet) {
                SettingsView()
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
            .onOpenURL { url in
                if url.host == "capture" {
                    // Toggle to trigger onChange in PersistentInputBar
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        triggerFocus = true
                        // Reset after a moment so it can be triggered again
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            triggerFocus = false
                        }
                    }
                } else if url.host == "paywall" {
                    showingPaywall = true
                }
            }
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
            try? modelContext.save()
            WidgetCenter.shared.reloadAllTimelines()
        }
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

    private func color(for days: Int?) -> Color {
        return .secondary
    }
}

#Preview {
    ContentView()
        .modelContainer(for: RememberedItem.self, inMemory: true)
}
