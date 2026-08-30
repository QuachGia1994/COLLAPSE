import SwiftUI

@main
@MainActor
struct CollapseApp: App {
    @State private var profile = PlayerProfile()
    @State private var entitlement = EntitlementStore()
    @State private var sensory = SensoryEngine()
    @State private var runActivity = RunActivityController()
    @State private var gameCenter = GameCenterStore()
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
            .environment(\.locale, Locale(identifier: profile.selectedLanguage.localeIdentifier))
            .environment(profile)
            .environment(entitlement)
            .environment(sensory)
            .environment(runActivity)
            .environment(gameCenter)
            .sheet(isPresented: authenticationSheetBinding) {
                if let controller = gameCenter.authenticationController {
                    GameCenterAuthenticationView(controller: controller)
                        .ignoresSafeArea()
                }
            }
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

    private var authenticationSheetBinding: Binding<Bool> {
        Binding(
            get: { gameCenter.authenticationController != nil },
            set: { isPresented in
                guard !isPresented else { return }
                gameCenter.dismissAuthenticationController()
            }
        )
    }

    private func bootstrap() async {
        gameCenter.start()
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
