import SwiftUI

struct WelcomeScreenView: View {
    var onContinue: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // SF Symbol illustration
            Image(systemName: "birthday.cake.fill")
                .font(.system(size: 64))
                .foregroundStyle(.blue)
                .symbolRenderingMode(.hierarchical)

            // Headline
            Text("Never forget an important date")
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            // Value props
            VStack(alignment: .leading, spacing: 16) {
                ValuePropRow(icon: "text.bubble", text: "Natural language input")
                ValuePropRow(icon: "bell.badge", text: "Smart reminders")
                ValuePropRow(icon: "square.grid.2x2", text: "Widget at a glance")
            }
            .padding(.horizontal, 32)
            .padding(.top, 8)

            Spacer()

            // Continue button
            Button(action: onContinue) {
                Text("Continue")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
    }
}

struct ValuePropRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 28)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()
        }
    }
}

#Preview {
    WelcomeScreenView(onContinue: {})
}
