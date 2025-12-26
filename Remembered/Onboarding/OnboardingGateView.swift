import SwiftUI
import SwiftData

struct OnboardingGateView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Query private var items: [RememberedItem]

    var body: some View {
        Group {
            if hasCompletedOnboarding || items.count > 0 {
                ContentView()
            } else {
                OnboardingContainerView()
            }
        }
        .onAppear {
            // Auto-skip onboarding if user already has data (iCloud restore edge case)
            if items.count > 0 && !hasCompletedOnboarding {
                hasCompletedOnboarding = true
            }
        }
    }
}
