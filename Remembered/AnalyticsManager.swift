import Foundation

enum AnalyticsManager {
    static func track(_ event: String, properties: [String: Any] = [:]) {
        #if !DEBUG
        // TODO: Integrate analytics service (TelemetryDeck, PostHog, etc.)
        #endif
        print("📊 Analytics: \(event) - \(properties)")
    }
}
