import Foundation
import UserNotifications

@MainActor
class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    func requestPermissions() async throws -> Bool {
        let center = UNUserNotificationCenter.current()
        let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
        return granted
    }
    
    func scheduleNotification(for item: RememberedItem) {
        // Safety check for Pro status
        guard StoreManager.shared.isPro else {
            print("NotificationManager: Gated - User is not Pro")
            return
        }
        
        // Cancel all existing notifications for this item first
        cancelNotification(for: item)
        
        guard item.isNotificationEnabled, let date = item.date else {
            return
        }
        
        for interval in item.notificationIntervals {
            let content = UNMutableNotificationContent()
            content.title = item.title
            content.body = "Reminder: \(item.title) is happening \(friendlyName(for: interval))."
            content.sound = .default
            
            var triggerDate = calculateTriggerDate(for: date, interval: interval)
            
            // If the trigger date is in the past and it's an annual recurrence, move it to next year
            if triggerDate < Date() && item.recurrence == "annual" {
                if let nextYear = Calendar.current.date(byAdding: .year, value: 1, to: triggerDate) {
                    triggerDate = nextYear
                }
            }
            
            // Only schedule if the date is in the future
            guard triggerDate > Date() else { continue }
            
            let calendar = Calendar.current
            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: item.recurrence == "annual")
            
            // Unique identifier for each interval
            let requestIdentifier = "\(item.id.uuidString)-\(interval)"
            let request = UNNotificationRequest(identifier: requestIdentifier, content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error scheduling notification for \(interval): \(error.localizedDescription)")
                }
            }
        }
    }
    
    func cancelNotification(for item: RememberedItem) {
        // Remove all possible interval notifications for this item
        let identifiers = [
            "\(item.id.uuidString)-oneMonth",
            "\(item.id.uuidString)-twoWeeks",
            "\(item.id.uuidString)-oneWeek",
            "\(item.id.uuidString)-threeDays",
            "\(item.id.uuidString)-oneDay",
            "\(item.id.uuidString)-dayOf"
        ]
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }
    
    private func friendlyName(for interval: String) -> String {
        switch interval {
        case "oneMonth": return "in 1 month"
        case "twoWeeks": return "in 2 weeks"
        case "oneWeek": return "in 1 week"
        case "threeDays": return "in 3 days"
        case "oneDay": return "tomorrow"
        case "dayOf": return "today"
        default: return "soon"
        }
    }
    
    private func calculateTriggerDate(for date: Date, interval: String) -> Date {
        let hour = UserDefaults.standard.integer(forKey: "notificationHour") == 0 && UserDefaults.standard.object(forKey: "notificationHour") == nil ? 9 : UserDefaults.standard.integer(forKey: "notificationHour")
        let minute = UserDefaults.standard.integer(forKey: "notificationMinute")
        
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = hour
        components.minute = minute
        
        let baseDate = calendar.date(from: components) ?? date
        
        switch interval {
        case "oneMonth":
            return calendar.date(byAdding: .month, value: -1, to: baseDate) ?? baseDate
        case "twoWeeks":
            return calendar.date(byAdding: .day, value: -14, to: baseDate) ?? baseDate
        case "oneWeek":
            return calendar.date(byAdding: .day, value: -7, to: baseDate) ?? baseDate
        case "threeDays":
            return calendar.date(byAdding: .day, value: -3, to: baseDate) ?? baseDate
        case "oneDay":
            return calendar.date(byAdding: .day, value: -1, to: baseDate) ?? baseDate
        default: // "dayOf"
            return baseDate
        }
    }
    
    func rescheduleAllNotifications(items: [RememberedItem]) {
        for item in items {
            scheduleNotification(for: item)
        }
    }
    
    func printPendingNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            print("--- Pending Notifications (\(requests.count)) ---")
            for request in requests {
                print("ID: \(request.identifier)")
                print("Title: \(request.content.title)")
                if let trigger = request.trigger as? UNCalendarNotificationTrigger {
                    let date = trigger.nextTriggerDate()?.formatted() ?? "Unknown"
                    print("Next Trigger: \(date)")
                }
                print("---")
            }
        }
    }
}
