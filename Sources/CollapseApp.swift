import SwiftUI

@main
@MainActor
struct CollapseApp: App {
    @State private var profile = PlayerProfile()
    @State private var entitlement = EntitlementStore()
    @State private var sensory = SensoryEngine()
    @State private var runActivity = RunActivityController()

    var body: some Scene {
        WindowGroup {
            rootContent
                .preferredColorScheme(.dark)
                .environment(profile)
                .environment(entitlement)
                .environment(sensory)
                .environment(runActivity)
                .task {
                    await runActivity.cleanupStaleActivities()
                }
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
}
