import SwiftUI
import SwiftData
import WidgetKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RememberedItem.date) private var items: [RememberedItem]

    @State private var showingSettingsSheet = false
    @State private var showingPaywall = false
    @State private var preFillText: String = ""
    @FocusState private var inputFocused: Bool
    @State private var keyboardHeight: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
        NavigationStack {
            VStack(spacing: 0) {
                if items.isEmpty {
                    EmptyStateView(
                        onExampleTapped: { example in
                            preFillText = example
                            inputFocused = true
                        },
                        onAddTapped: {
                            preFillText = ""
                            inputFocused = true
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

                PersistentInputBar(preFillText: $preFillText, shouldFocus: inputFocused)
            }
            .padding(.bottom, keyboardHeight)
            .ignoresSafeArea(.keyboard)
            .navigationTitle("Dates")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { showingSettingsSheet = true }) {
                        Label("Settings", systemImage: "gear")
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
                if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                    withAnimation(.easeOut(duration: 0.3)) {
                        keyboardHeight = keyboardFrame.height - geometry.safeAreaInsets.bottom
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                withAnimation(.easeOut(duration: 0.3)) {
                    keyboardHeight = 0
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
                    inputFocused = true
                } else if url.host == "paywall" {
                    showingPaywall = true
                }
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
