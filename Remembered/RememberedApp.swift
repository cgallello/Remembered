import SwiftUI
import SwiftData

@main
struct RememberedApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            RememberedItem.self,
        ])
        
        // Use App Group URL for shared data
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

    @StateObject private var storeManager = StoreManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(storeManager)
        }
        .modelContainer(sharedModelContainer)
    }
}
