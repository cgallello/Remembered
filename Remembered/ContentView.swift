import SwiftUI
import SwiftData
import WidgetKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RememberedItem.date) private var items: [RememberedItem]
    
    @State private var showingCaptureSheet = false
    @State private var showingSettingsSheet = false
    @State private var showingPaywall = false
    @State private var preFillText: String = ""

    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    EmptyStateView(
                        onExampleTapped: { example in
                            preFillText = example
                            showingCaptureSheet = true
                        },
                        onAddTapped: {
                            preFillText = ""
                            showingCaptureSheet = true
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
            }
            .navigationTitle("Dates")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { showingSettingsSheet = true }) {
                        Label("Settings", systemImage: "gear")
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingCaptureSheet = true }) {
                        Label("Add", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCaptureSheet) {
                CaptureView(initialText: preFillText)
                    .presentationDetents([.fraction(0.35), .medium])
                    .presentationDragIndicator(.visible)
                    .onDisappear {
                        preFillText = ""
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
                    showingCaptureSheet = true
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
