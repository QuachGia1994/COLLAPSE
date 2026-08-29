import SwiftUI

@main
@MainActor
struct CollapseApp: App {
    @State private var profile = PlayerProfile()
    @State private var entitlement = EntitlementStore()

    var body: some Scene {
        WindowGroup {
            Group {
                if profile.didCompleteTutorial {
                    HomeView()
                } else {
                    TutorialView()
                }
            }
            .preferredColorScheme(.dark)
            .environment(profile)
            .environment(entitlement)
        }
    }
}
