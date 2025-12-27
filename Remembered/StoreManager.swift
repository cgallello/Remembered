import Foundation
import StoreKit
import Combine
import WidgetKit

@MainActor
class StoreManager: ObservableObject {
    static let shared = StoreManager()
    
    @Published private(set) var products: [Product] = []
    @Published private(set) var isPro: Bool = false {
        didSet {
            // Persist to shared UserDefaults for Widget access
            Configuration.sharedUserDefaults?.set(isPro, forKey: "isPro")
            WidgetCenter.shared.reloadAllTimelines()
            print("StoreManager: isPro set to \(isPro) and widget reloaded")
        }
    }
    
    private var transactionListener: Task<Void, Error>?
    
    private init() {
        // Load initial state from disk
        self.isPro = Configuration.sharedUserDefaults?.bool(forKey: "isPro") ?? false
        
        // Listen for transaction updates
        transactionListener = Task.detached {
            for await result in Transaction.updates {
                await self.handle(transactionVerification: result)
            }
        }
        
        Task {
            await loadProducts()
            await updatePurchaseStatus()
        }
    }
    
    deinit {
        transactionListener?.cancel()
    }
    
    func loadProducts() async {
        for attempt in 1...3 {
            do {
                products = try await Product.products(for: [Configuration.lifetimeProductID])
                print("StoreManager: Loaded \(products.count) products on attempt \(attempt)")

                if !products.isEmpty {
                    return
                }

                if attempt < 3 {
                    print("StoreManager: No products loaded - retrying in \(attempt) seconds")
                    try await Task.sleep(nanoseconds: UInt64(attempt) * 1_000_000_000)
                }
            } catch {
                print("StoreManager: Failed to load products on attempt \(attempt): \(error)")
                if attempt < 3 {
                    try? await Task.sleep(nanoseconds: UInt64(attempt) * 1_000_000_000)
                }
            }
        }
        print("StoreManager: Failed to load products after 3 attempts")
    }
    
    func purchase() async throws -> Bool {
        guard let product = products.first(where: { $0.id == Configuration.lifetimeProductID }) else {
            print("StoreManager: Product not found")
            return false
        }
        
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            await handle(transactionVerification: verification)

            // Haptic feedback for successful purchase
            HapticManager.success()

            return true
        case .userCancelled, .pending:
            return false
        @unknown default:
            return false
        }
    }
    
    func restore() async {
        do {
            try await AppStore.sync()
            await updatePurchaseStatus()
        } catch {
            print("StoreManager: Restore failed: \(error)")
        }
    }
    
    func debugTogglePro() {
        isPro.toggle()
        print("StoreManager: DEBUG - isPro is now \(isPro)")
    }
    
    private func updatePurchaseStatus() async {
        for await result in Transaction.currentEntitlements {
            await handle(transactionVerification: result)
        }
    }
    
    private func handle(transactionVerification result: VerificationResult<Transaction>) async {
        switch result {
        case .verified(let transaction):
            if transaction.productID == Configuration.lifetimeProductID {
                isPro = transaction.revocationDate == nil
                await transaction.finish()
            }
        case .unverified:
            // Verification failed, stay locked
            break
        }
    }
}
