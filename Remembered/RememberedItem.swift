import Foundation
import SwiftData

enum Configuration {
    static let appName = "Remembered"
    static let appGroupID = "group.cgallello.Remembered"
    static let lifetimeProductID = "com.cgallello.remembered.lifetime"
    
    static var sharedUserDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }
}

@Model
final class RememberedItem {
    var id: UUID
    var rawInput: String
    var title: String
    var date: Date?
    var type: String // "birthday", "anniversary", "medical", "other"
    var recurrence: String // "none", "annual"
    var needsReview: Bool
    var notes: String
    var createdAt: Date
    var updatedAt: Date
    
    var isNotificationEnabled: Bool
    var notificationIntervals: [String] // "oneMonth", "twoWeeks", "oneWeek", "threeDays", "oneDay", "dayOf"

    // Contact linkage (optional)
    var contactId: String?              // CNContact identifier
    var contactDisplayName: String?     // Snapshot of contact name at time of linking

    init(rawInput: String, title: String? = nil, date: Date? = nil, type: String = "other", recurrence: String = "none", notes: String = "", needsReview: Bool = false, isNotificationEnabled: Bool = false, notificationIntervals: [String] = ["oneWeek", "dayOf"], contactId: String? = nil, contactDisplayName: String? = nil) {
        self.id = UUID()
        self.rawInput = rawInput
        self.title = title ?? rawInput
        self.date = date
        self.type = type
        self.recurrence = recurrence
        self.notes = notes
        self.needsReview = needsReview
        self.isNotificationEnabled = isNotificationEnabled
        self.notificationIntervals = notificationIntervals
        self.contactId = contactId
        self.contactDisplayName = contactDisplayName
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    var daysUntil: Int? {
        guard let date = date else { return nil }
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let startOfTarget = calendar.startOfDay(for: date)
        
        let components = calendar.dateComponents([.day], from: startOfToday, to: startOfTarget)
        return components.day
    }
    
    var countdownString: String {
        guard let days = daysUntil else { return "" }
        if days == 0 { return "Today" }
        if days == 1 { return "Tomorrow" }
        if days == -1 { return "Yesterday" }
        if days > 0 { return "\(days) days" } // Drier: "In 5 days" -> "5 days"
        return "\(abs(days)) days past" // Drier: "5 days ago" -> "5 days past"
    }
}
