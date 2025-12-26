import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var storeManager = StoreManager.shared
    @State private var isPurchasing = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "sparkles")
                    .font(.system(size: 60))
                    .foregroundStyle(.primary)
                
                Text("Unlock all features")
                    .font(.largeTitle.bold())

                VStack(spacing: 8) {
                    Text("One-time purchase • No subscription")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text("Support development and unlock essential features forever.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 40)
            }
            
            VStack(alignment: .leading, spacing: 20) {
                FeatureRow(icon: "bell.badge", title: "Push Notifications", description: "Receive reminders at your preferred time.")
                FeatureRow(icon: "square.grid.2x2", title: "Home Screen Widgets", description: "Keep your important dates in sight.")
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            VStack(spacing: 16) {
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
                        if storeManager.isPro {
                            dismiss()
                        }
                    }
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
                
                Button("Not Now") {
                    dismiss()
                }
                .font(.footnote)
                .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 24)
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
                dismiss()
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

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.primary)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    PaywallView()
}
