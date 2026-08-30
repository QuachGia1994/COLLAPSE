import SwiftUI

@main
@MainActor
struct CollapseApp: App {
    @State private var profile = PlayerProfile()
    @State private var entitlement = EntitlementStore()
    @State private var sensory = SensoryEngine()
    @State private var music = BackgroundMusicPlayer()
    @State private var runActivity = RunActivityController()
    @State private var gameCenter = GameCenterStore()
    @State private var isShowingStartup = true
    @Environment(\.scenePhase) private var scenePhase

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
            .onChange(of: scenePhase) { _, phase in
                switch phase {
                case .active:
                    if profile.musicEnabled { music.play() }
                case .background:
                    music.pause()
                default:
                    break
                }
            }
            .onChange(of: profile.musicEnabled) { _, enabled in
                if enabled && scenePhase == .active {
                    music.play()
                } else {
                    music.pause()
                }
            }
            .onChange(of: profile.soundEnabled) { _, enabled in
                sensory.soundEnabled = enabled
            }
            .onChange(of: profile.hapticsEnabled) { _, enabled in
                sensory.hapticsEnabled = enabled
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
        sensory.soundEnabled = profile.soundEnabled
        sensory.hapticsEnabled = profile.hapticsEnabled
        if profile.musicEnabled { music.play() }
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
