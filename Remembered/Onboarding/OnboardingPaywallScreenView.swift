import SwiftUI
import StoreKit

struct OnboardingPaywallScreenView: View {
    @StateObject private var storeManager = StoreManager.shared
    var onContinue: () -> Void

    @State private var isPurchasing = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "sparkles")
                    .font(.system(size: 64))
                    .foregroundStyle(.blue)
                    .symbolRenderingMode(.hierarchical)

                Text("Free forever")
                    .font(.title2.bold())

                VStack(spacing: 8) {
                    Text("Use Remembered for free with unlimited dates.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Text("Upgrade once to unlock essential features.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)
            }

            VStack(alignment: .leading, spacing: 16) {
                FeatureRow(icon: "bell.badge", title: "Push Notifications", description: "Receive reminders at your preferred time")
                FeatureRow(icon: "square.grid.2x2", title: "Home Screen Widget", description: "Keep your important dates in sight")
            }
            .padding(.horizontal, 32)

            Spacer()

            VStack(spacing: 12) {
                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                if let product = storeManager.products.first {
                    Button {
                        purchase(product)
                    } label: {
                        Group {
                            if isPurchasing {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                VStack(spacing: 4) {
                                    Text("\(product.displayPrice)")
                                        .font(.title2.bold())
                                    Text("One-time purchase")
                                        .font(.caption)
                                        .opacity(0.8)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.primary)
                        .foregroundStyle(Color(.systemBackground))
                        .cornerRadius(12)
                    }
                    .disabled(isPurchasing)
                } else {
                    Button {
                        // Fallback for development/testing
                        storeManager.debugTogglePro()
                    } label: {
                        VStack(spacing: 4) {
                            Text("$1.99")
                                .font(.title2.bold())
                            Text("One-time purchase")
                                .font(.caption)
                                .opacity(0.8)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.primary)
                        .foregroundStyle(Color(.systemBackground))
                        .cornerRadius(12)
                    }
                }

                Button("Restore Purchase") {
                    Task {
                        await storeManager.restore()
                    }
                }
                .font(.footnote)
                .foregroundStyle(.secondary)

                Button(action: onContinue) {
                    Text("Continue")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
        .onAppear {
            Task {
                if storeManager.products.isEmpty {
                    await storeManager.loadProducts()
                }
            }
        }
        .onChange(of: storeManager.isPro) { _, newValue in
            if newValue {
                // Auto-continue if purchase successful
                onContinue()
            }
        }
    }

    private func purchase(_ product: Product) {
        isPurchasing = true
        errorMessage = nil

        Task {
            do {
                let success = try await storeManager.purchase()
                if !success {
                    // User cancelled or pending
                }
            } catch {
                errorMessage = "Purchase failed. Please try again."
            }
            isPurchasing = false
        }
    }
}

#Preview {
    OnboardingPaywallScreenView(onContinue: {})
}
