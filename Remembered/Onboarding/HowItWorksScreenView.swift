import SwiftUI

struct HowItWorksScreenView: View {
    var onContinue: () -> Void

    @State private var showParsedResult = false

    let exampleInput = "Mom's birthday March 15"

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Headline
            Text("Just type naturally")
                .font(.title2)
                .fontWeight(.semibold)

            // Demo container
            VStack(spacing: 20) {
                // Input text
                Text("\"\(exampleInput)\"")
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .opacity(showParsedResult ? 0.5 : 1.0)

                // Arrow indicator
                Image(systemName: "arrow.down")
                    .font(.title2)
                    .foregroundStyle(.blue)
                    .opacity(showParsedResult ? 1.0 : 0.3)

                // Parsed result
                if showParsedResult {
                    let parsedResult = DateParser.parse(exampleInput)

                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            Text(icon(for: parsedResult.type))
                                .font(.title2)
                            Text(parsedResult.title)
                                .font(.headline)
                            Spacer()
                        }

                        HStack {
                            Image(systemName: "calendar")
                                .foregroundStyle(.secondary)
                            if let date = parsedResult.date {
                                Text(date.formatted(.dateTime.month(.wide).day().year()))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.tertiarySystemBackground))
                    .cornerRadius(12)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 32)

            // Explainer text
            Text("We'll understand dates, names,\nand types automatically")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

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
        .onAppear {
            // Trigger animation after 0.8s delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showParsedResult = true
                }
            }
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

#Preview {
    HowItWorksScreenView(onContinue: {})
}
