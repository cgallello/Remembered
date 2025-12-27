import SwiftUI
import SwiftData
import Contacts
import WidgetKit

struct BirthdayImportView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var contacts: [ContactBirthday] = []
    @State private var permissionStatus: CNAuthorizationStatus = .notDetermined
    @State private var isLoading = false
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 12) {
                Text("Import birthdays")
                    .font(.largeTitle)
                    .bold()

                Text("Import birthdays from your contacts to get started quickly. You can always add more later.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.top, 40)

            // Content based on permission status
            if isLoading {
                Spacer()
                ProgressView()
                Spacer()
            } else if permissionStatus == .authorized {
                if contacts.isEmpty {
                    noContactsView
                } else {
                    birthdayList
                }
            } else if permissionStatus == .notDetermined {
                requestPermissionView
            } else {
                deniedView
            }

            Spacer()

            // Actions
            actionButtons
        }
        .padding()
        .onAppear {
            checkPermission()
        }
    }

    // MARK: - Subviews

    private var birthdayList: some View {
        List {
            ForEach($contacts) { $contact in
                Toggle(isOn: $contact.isSelected) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(contact.name)
                        Text(formatBirthday(contact.birthday))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var requestPermissionView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "person.crop.circle")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("Contacts permission needed to import birthdays")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button(action: requestPermission) {
                Text("Allow Access to Contacts")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
        .padding()
    }

    private var deniedView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "person.crop.circle.badge.xmark")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("Contacts access is disabled")
                .font(.headline)

            Text("To import birthdays, please enable Contacts access in Settings.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button(action: openSettings) {
                Text("Open Settings")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
        .padding()
    }

    private var noContactsView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "birthday.cake")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No birthdays found")
                .font(.headline)

            Text("None of your contacts have birthdays set. You can add dates manually later.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            if permissionStatus == .authorized && !contacts.isEmpty {
                let selectedCount = contacts.filter(\.isSelected).count
                Button(action: importBirthdays) {
                    Text("Import \(selectedCount) birthday\(selectedCount == 1 ? "" : "s")")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedCount == 0)
            }

            Button(action: onContinue) {
                Text(permissionStatus == .authorized && !contacts.isEmpty ? "Skip" : "Continue")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .padding(.horizontal)
    }

    // MARK: - Helper Methods

    private func checkPermission() {
        permissionStatus = ContactManager.shared.checkPermissionStatus()
        if permissionStatus == .authorized {
            loadContacts()
        }
    }

    private func requestPermission() {
        isLoading = true
        Task {
            let granted = await ContactManager.shared.requestPermission()
            await MainActor.run {
                permissionStatus = granted ? .authorized : .denied
                if granted {
                    loadContacts()
                }
                isLoading = false
            }
        }
    }

    private func loadContacts() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            // Clear cache to ensure fresh data (important for Settings re-sync)
            ContactManager.shared.clearCache()
            let fetchedContacts = ContactManager.shared.fetchContactsWithBirthdays()

            DispatchQueue.main.async {
                contacts = fetchedContacts
                isLoading = false
            }
        }
    }

    private func importBirthdays() {
        let selected = contacts.filter(\.isSelected)

        for contact in selected {
            // Check if entry already exists for this contact
            let contactIdToFind = contact.id
            let descriptor = FetchDescriptor<RememberedItem>()
            let allItems = (try? modelContext.fetch(descriptor)) ?? []
            let existingItem = allItems.first { $0.contactId == contactIdToFind }

            if let existingItem = existingItem {
                // Update existing entry's birthday
                let nextBirthday = calculateNextOccurrence(of: contact.birthday)
                existingItem.date = nextBirthday
                existingItem.updatedAt = Date()
            } else {
                // Create new entry
                let nextBirthday = calculateNextOccurrence(of: contact.birthday)
                let item = RememberedItem(
                    rawInput: "\(contact.name) birthday",
                    title: contact.name,
                    date: nextBirthday,
                    type: "birthday",
                    contactId: contact.id,
                    contactDisplayName: contact.name
                )
                modelContext.insert(item)
            }
        }

        try? modelContext.save()
        WidgetCenter.shared.reloadAllTimelines()
        onContinue()
    }

    private func openSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
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

    private func formatBirthday(_ birthday: DateComponents) -> String {
        let calendar = Calendar.current
        guard let date = calendar.date(from: birthday) else { return "" }

        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        return formatter.string(from: date)
    }
}

#Preview {
    BirthdayImportView(onContinue: {})
        .modelContainer(for: RememberedItem.self, inMemory: true)
}
