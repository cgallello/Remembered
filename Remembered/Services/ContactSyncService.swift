import Foundation
import SwiftData
import Contacts
import WidgetKit

class ContactSyncService {
    static let shared = ContactSyncService()
    private init() {}

    private let lastSyncKey = "lastBirthdaySyncDate"
    private let syncInterval: TimeInterval = 24 * 60 * 60 // 24 hours

    func syncBirthdaysIfNeeded(modelContainer: ModelContainer) async {
        // Check if we should sync (throttle to once per 24 hours)
        if !shouldSync() {
            return
        }

        // Only sync if permission granted
        guard ContactManager.shared.checkPermissionStatus() == .authorized else {
            return
        }

        await syncBirthdays(modelContainer: modelContainer)

        // Update last sync timestamp
        UserDefaults.standard.set(Date(), forKey: lastSyncKey)
    }

    private func shouldSync() -> Bool {
        guard let lastSync = UserDefaults.standard.object(forKey: lastSyncKey) as? Date else {
            return true // Never synced before
        }

        let timeSinceLastSync = Date().timeIntervalSince(lastSync)
        return timeSinceLastSync >= syncInterval
    }

    func syncBirthdays(modelContainer: ModelContainer) async {
        // Create background context
        let modelContext = ModelContext(modelContainer)

        // Fetch all entries with contactId
        let descriptor = FetchDescriptor<RememberedItem>()
        guard let items = try? modelContext.fetch(descriptor) else { return }

        let itemsWithContacts = items.filter { $0.contactId != nil }

        var hasChanges = false

        for item in itemsWithContacts {
            guard let contactId = item.contactId else { continue }

            // Check if contact still exists and get current birthday
            if let birthday = ContactManager.shared.syncBirthdayForContact(id: contactId) {
                // Calculate next occurrence
                let nextOccurrence = calculateNextOccurrence(of: birthday)

                // Update birthday if changed
                if item.date != nextOccurrence {
                    item.date = nextOccurrence
                    item.updatedAt = Date()
                    hasChanges = true
                }
            } else {
                // Contact was deleted - clear contactId but keep entry
                item.contactId = nil
                // Keep contactDisplayName as snapshot
                hasChanges = true
            }
        }

        // Save changes if any
        if hasChanges {
            try? modelContext.save()

            // Reload widget on main thread
            await MainActor.run {
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
    }

    private func calculateNextOccurrence(of birthday: DateComponents) -> Date {
        let calendar = Calendar.current
        let now = Date()
        let currentYear = calendar.component(.year, from: now)

        var nextBirthday = birthday
        nextBirthday.year = currentYear

        guard let date = calendar.date(from: nextBirthday) else { return now }

        // If birthday already passed this year, use next year
        if date < now {
            nextBirthday.year = currentYear + 1
            return calendar.date(from: nextBirthday) ?? date
        }

        return date
    }
}
