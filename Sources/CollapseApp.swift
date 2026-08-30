import SwiftUI

@main
@MainActor
struct CollapseApp: App {
    @State private var profile = PlayerProfile()
    @State private var entitlement = EntitlementStore()
    @State private var sensory = SensoryEngine()
    @State private var runActivity = RunActivityController()
    @State private var isShowingStartup = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                rootContent
                if isShowingStartup {
                    StartupView()
                        .transition(.opacity)
                        .zIndex(10)
                }
            }
            .preferredColorScheme(.dark)
            .environment(profile)
            .environment(entitlement)
            .environment(sensory)
            .environment(runActivity)
            .task { await bootstrap() }
        }
    }

    @ViewBuilder
    private var rootContent: some View {
        if profile.didCompleteTutorial {
            HomeView()
        } else {
            TutorialView()
        }
    }

    private func bootstrap() async {
        await runActivity.cleanupStaleActivities()
        do {
            try await Task.sleep(for: .milliseconds(720))
        } catch {
            return
        }
        withAnimation(.easeOut(duration: 0.24)) {
            isShowingStartup = false
        }
    }
}
