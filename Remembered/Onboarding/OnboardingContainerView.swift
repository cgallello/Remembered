import SwiftUI

struct OnboardingContainerView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentScreen = 0
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // Full-screen background
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Custom page indicator
                HStack(spacing: 8) {
                    ForEach(0..<5) { index in
                        Circle()
                            .fill(index == currentScreen ? Color.blue : Color.secondary.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 8)

                // TabView with screens
                TabView(selection: $currentScreen) {
                    WelcomeScreenView(onContinue: {
                        withAnimation {
                            currentScreen = 1
                        }
                        AnalyticsManager.track("onboarding_screen_viewed", properties: ["screen": "how_it_works"])
                    })
                    .tag(0)

                    HowItWorksScreenView(onContinue: {
                        withAnimation {
                            currentScreen = 2
                        }
                        AnalyticsManager.track("onboarding_screen_viewed", properties: ["screen": "first_date"])
                    })
                    .tag(1)

                    FirstDateScreenView(onComplete: {
                        withAnimation {
                            currentScreen = 3
                        }
                        AnalyticsManager.track("onboarding_screen_viewed", properties: ["screen": "birthday_import"])
                    })
                    .tag(2)

                    BirthdayImportView(onContinue: {
                        withAnimation {
                            currentScreen = 4
                        }
                        AnalyticsManager.track("onboarding_screen_viewed", properties: ["screen": "paywall"])
                    })
                    .tag(3)

                    OnboardingPaywallScreenView(onContinue: {
                        completeOnboarding()
                    })
                    .tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentScreen)
            }
        }
        .onAppear {
            // Track onboarding start
            AnalyticsManager.track("onboarding_started")
            AnalyticsManager.track("onboarding_screen_viewed", properties: ["screen": "welcome"])
        }
    }

    private func completeOnboarding() {
        // Track completion
        AnalyticsManager.track("onboarding_completed")

        // Mark as complete
        hasCompletedOnboarding = true

        // Dismiss if presented as modal (safe to call even if not modal)
        dismiss()
    }
}

#Preview {
    OnboardingContainerView()
}
