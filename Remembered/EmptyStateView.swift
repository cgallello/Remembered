import SwiftUI

struct EmptyStateView: View {
    var onExampleTapped: (String) -> Void
    var onAddTapped: () -> Void

    private let examples = [
        "Mom's birthday March 15",
        "Our anniversary October 3rd",
        "Dad's birthday next Tuesday"
    ]

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // SF Symbol illustration (birthday cake)
            Image(systemName: "birthday.cake.fill")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            // Headline
            Text("Your important dates live here")
                .font(.title2)
                .fontWeight(.semibold)

            // Subhead
            Text("Add birthdays, anniversaries, and dates\nyou never want to forget.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            // Primary CTA
            Button("Add your first date") {
                onAddTapped()
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)

            // Divider with "or try an example"
            Text("or try an example")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.top, 16)

            // Tappable example phrases
            VStack(spacing: 12) {
                ForEach(examples, id: \.self) { example in
                    Button {
                        onExampleTapped(example)
                    } label: {
                        Text("\"\(example)\"")
                            .font(.subheadline)
                            .foregroundStyle(.blue)
                    }
                }
            }

            Spacer()
        }
        .padding()
    }
}

#Preview {
    EmptyStateView(
        onExampleTapped: { example in
            print("Tapped example: \(example)")
        },
        onAddTapped: {
            print("Tapped add button")
        }
    )
}
