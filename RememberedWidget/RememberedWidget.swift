import WidgetKit
import SwiftUI
import SwiftData

struct Provider: TimelineProvider {
    // Shared container setup for the widget target
    static var sharedModelContainer: ModelContainer = {
        let schema = Schema([RememberedItem.self])
        let groupID = Configuration.appGroupID
        guard let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID) else {
            fatalError("Could not find App Group container")
        }
        let url = groupURL.appendingPathComponent("default.store")
        let modelConfiguration = ModelConfiguration(schema: schema, url: url)
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), items: [], isPro: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let isPro = Configuration.sharedUserDefaults?.bool(forKey: "isPro") ?? false
        
        Task {
            let items = isPro ? await fetchUpcomingItems() : []
            let entry = SimpleEntry(date: Date(), items: items, isPro: isPro)
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let isPro = Configuration.sharedUserDefaults?.bool(forKey: "isPro") ?? false
        
        Task {
            let items = isPro ? await fetchUpcomingItems() : []
            let entry = SimpleEntry(date: Date(), items: items, isPro: isPro)
            let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }
    
    @MainActor
    private func fetchUpcomingItems() -> [EntryData] {
        let context = Self.sharedModelContainer.mainContext
        let descriptor = FetchDescriptor<RememberedItem>(
            sortBy: [SortDescriptor(\.date)]
        )
        
        do {
            let items = try context.fetch(descriptor)
            // Filter and map all upcoming or today dates
            return items
                .filter { ($0.daysUntil ?? -1) >= 0 }
                .prefix(20) // Fetch more to support large grid
                .map { match in
                    EntryData(
                        title: match.title,
                        countdown: match.countdownString,
                        dateString: match.date?.formatted(.dateTime.month().day()) ?? "",
                        type: match.type
                    )
                }
        } catch {
            return []
        }
    }
}

struct EntryData {
    let title: String
    let countdown: String
    let dateString: String
    let type: String
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let items: [EntryData]
    let isPro: Bool
}

struct RememberedWidgetEntryView : View {
    @Environment(\.widgetFamily) var family
    var entry: Provider.Entry

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if !entry.isPro {
                    paywallView()
                } else if entry.items.isEmpty {
                    Text("No upcoming dates")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    switch family {
                    case .systemSmall:
                        smallGrid()
                    case .systemMedium, .systemLarge:
                        mediumLargeGrid()
                    default:
                        smallGrid()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            
            // Link for the "+" button in bottom right
            Link(destination: URL(string: "importantdates://capture")!) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.primary)
                    .background(Circle().fill(.ultraThinMaterial))
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
        .widgetURL(URL(string: entry.isPro ? "importantdates://home" : "importantdates://paywall")!)
    }
    
    private func paywallView() -> some View {
        VStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.title2)
            Text("Pro Required")
                .font(.headline)
            Text("Unlock on app")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .padding()
    }
    
    // 1 Column, 3 Rows
    private func smallGrid() -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(entry.items.prefix(3), id: \.title) { item in
                miniRow(item)
                if item.title != entry.items.prefix(3).last?.title {
                    Divider().opacity(0.15)
                }
            }
            Spacer(minLength: 0)
        }
    }
    
    // 2 Columns Grid
    private func mediumLargeGrid() -> some View {
        let rowsPerColumn = family == .systemLarge ? 7 : 3
        let columnSpacing: CGFloat = 12
        let rowSpacing: CGFloat = 8
        
        return HStack(alignment: .top, spacing: columnSpacing) {
            // Left Column
            VStack(alignment: .leading, spacing: rowSpacing) {
                let leftItems = entry.items.prefix(rowsPerColumn)
                ForEach(leftItems, id: \.title) { item in
                    gridRow(item)
                    if item.title != leftItems.last?.title {
                        Divider().opacity(0.15)
                    }
                }
                Spacer(minLength: 0)
            }
            
            // Right Column
            if entry.items.count > rowsPerColumn {
                VStack(alignment: .leading, spacing: rowSpacing) {
                    let rightItems = entry.items.dropFirst(rowsPerColumn).prefix(rowsPerColumn)
                    ForEach(rightItems, id: \.title) { item in
                        gridRow(item)
                        if item.title != rightItems.last?.title {
                            Divider().opacity(0.15)
                        }
                    }
                    Spacer(minLength: 0)
                }
            } else {
                Spacer(minLength: 0)
            }
        }
    }
    
    // Minimal row for Small widget
    private func miniRow(_ item: EntryData) -> some View {
        HStack(spacing: 6) {
            Text(icon(for: item.type))
                .font(.system(size: 14))
            
            VStack(alignment: .leading, spacing: 0) {
                Text(item.title)
                    .font(.system(size: 12, weight: .bold))
                    .lineLimit(1)
                
                Text(item.countdown.replacingOccurrences(of: " days", with: "d").replacingOccurrences(of: " past", with: "p"))
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.primary.opacity(0.8))
            }
            Spacer(minLength: 0)
        }
    }

    // Grid row for Medium/Large
    private func gridRow(_ item: EntryData) -> some View {
        HStack(alignment: .center, spacing: 8) {
            Text(icon(for: item.type))
                .font(.system(size: 18))
            
            VStack(alignment: .leading, spacing: 1) {
                Text(item.title)
                    .font(.system(size: 13, weight: .bold))
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    Text(item.dateString)
                        .font(.system(size: 11))
                        .foregroundStyle(.primary.opacity(0.7))
                    
                    Text(item.countdown.replacingOccurrences(of: " days", with: "d"))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.primary.opacity(0.7))
                }
            }
            Spacer(minLength: 0)
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
}

struct RememberedWidget: Widget {
    let kind: String = "RememberedWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            RememberedWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Upcoming Dates")
        .description("Never forget what matters.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryRectangular, .accessoryInline])
    }
}
