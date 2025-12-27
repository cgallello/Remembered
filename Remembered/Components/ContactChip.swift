import SwiftUI

struct ContactChip: View {
    let contactName: String
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text(truncatedName)
                .font(.body)
                .foregroundColor(.primary)
                .lineLimit(1)

            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(.secondarySystemFill))
        .cornerRadius(16)
    }

    private var truncatedName: String {
        if contactName.count > 15 {
            return String(contactName.prefix(15)) + "..."
        }
        return contactName
    }
}

#Preview {
    VStack(spacing: 16) {
        ContactChip(contactName: "Stef") {
            print("Delete tapped")
        }

        ContactChip(contactName: "Christopher Anderson") {
            print("Delete tapped")
        }

        ContactChip(contactName: "Sam") {
            print("Delete tapped")
        }
    }
    .padding()
}
