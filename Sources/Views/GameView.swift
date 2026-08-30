import SwiftUI

@MainActor
struct GameView: View {
    @Environment(PlayerProfile.self) private var profile
    @Environment(EntitlementStore.self) private var entitlement
    @Environment(SensoryEngine.self) private var sensory
    @Environment(RunActivityController.self) private var runActivity
    @Environment(\.scenePhase) private var scenePhase
    @State private var engine = GameEngine()
    @State private var pausedByScenePhase = false

    var body: some View {
        ZStack {
            GameBoardView(engine: engine, skin: activeSkin)
                .ignoresSafeArea()
            hud
            if engine.state == .paused { pauseCard }
            if engine.state == .gameOver { deathCard }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task { await startRun() }
        .onChange(of: engine.score) { _, score in updateLiveActivity(score: score) }
        .onChange(of: engine.state) { _, state in handleStateChange(state) }
        .onChange(of: scenePhase) { _, phase in handleScenePhase(phase) }
        .onDisappear { handleDisappear() }
    }

    private var activeSkin: GameSkin {
        profile.activeSkin(isPlusUnlocked: entitlement.isPlusUnlocked)
    }

    private var hud: some View {
        VStack {
            topHUD
            Spacer()
            if engine.phase == .choosing, engine.state == .playing { choiceHint }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var topHUD: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 7) {
                Text("COLLAPSE")
                    .font(.caption.weight(.medium))
                    .tracking(4)
                    .foregroundStyle(.white.opacity(0.78))
                Label("DỰ BÁO \(engine.choiceDuration, format: .number.precision(.fractionLength(1)))s", systemImage: "eye")
                    .font(.caption2.monospaced().weight(.semibold))
                    .foregroundStyle(activeSkin.palette.primary)
                Text("🔥 \(profile.dailyRunStreak) ngày  ·  ◆ \(profile.gemBalance + engine.economy.gems)")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.white.opacity(0.62))
            }
            Spacer()
            scoreControls
        }
        .padding(14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.10), lineWidth: 1)
        }
    }

    private var scoreControls: some View {
        VStack(alignment: .trailing, spacing: 5) {
            Text("\(engine.score)")
                .font(.system(size: 38, weight: .semibold, design: .rounded))
            Text("ĐIỂM")
                .font(.caption2)
                .tracking(2)
                .foregroundStyle(.white.opacity(0.50))
            Button {
                engine.pause()
            } label: {
                Image(systemName: "pause.fill")
                    .font(.caption.weight(.semibold))
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.circle)
            .opacity(engine.state == .playing ? 1 : 0)
            .disabled(engine.state != .playing)
        }
    }

    private var choiceHint: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(engine.guidanceQuality > 0.5 ? Color.green : Color.red)
                .frame(width: 7, height: 7)
            Text("CHẠM ĐỂ ĐỔI TƯƠNG LAI")
        }
        .font(.caption.weight(.semibold))
        .tracking(1.4)
        .foregroundStyle(.white.opacity(0.80))
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.regularMaterial, in: Capsule())
        .overlay { Capsule().stroke(.white.opacity(0.10), lineWidth: 1) }
        .padding(.bottom, 12)
        .allowsHitTesting(false)
    }

    private var pauseCard: some View {
        VStack(spacing: 14) {
            Image(systemName: "pause.circle.fill")
                .font(.system(size: 38))
                .foregroundStyle(activeSkin.palette.primary)
            Text("TẠM DỪNG")
                .font(.headline)
                .tracking(2)
            Button("TIẾP TỤC") { engine.resume() }
                .buttonStyle(.borderedProminent)
                .tint(activeSkin.palette.primary)
        }
        .padding(24)
        .frame(maxWidth: 280)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    private var deathCard: some View {
        VStack(spacing: 14) {
            Text("MẤT DÒNG THỜI GIAN")
                .font(.title2.weight(.semibold))
                .tracking(3)
            Text("Dự báo đã cho thấy tương lai này đi xuyên vùng đỏ.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            HStack(spacing: 20) {
                stat("ĐIỂM", value: "\(engine.score)")
                stat("GEM", value: "+\(engine.economy.gems)")
                stat("KỶ LỤC", value: "\(profile.bestScore)")
            }
            Button("THỬ TƯƠNG LAI KHÁC") {
                engine.restart()
                Task { await startLiveActivity() }
            }
            .buttonStyle(.borderedProminent)
            .tint(activeSkin.palette.primary)
        }
        .padding(24)
        .frame(maxWidth: 350)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        }
        .padding(24)
    }

    private func stat(_ title: String, value: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.title3.monospacedDigit().weight(.semibold))
            Text(title)
                .font(.caption2)
                .tracking(1.5)
                .foregroundStyle(.secondary)
        }
    }

    private func startRun() async {
        engine.connectSensory(sensory.client)
        profile.registerRunStart()
        engine.start()
        await startLiveActivity()
    }

    private func startLiveActivity() async {
        await runActivity.start(
            streak: profile.dailyRunStreak,
            bestScore: profile.bestScore,
            localRank: profile.localRank(for: engine.score)
        )
    }

    private func updateLiveActivity(score: Int) {
        Task {
            await runActivity.update(
                score: score,
                bestScore: max(profile.bestScore, score),
                streak: profile.dailyRunStreak,
                localRank: profile.localRank(for: score),
                status: .playing
            )
        }
    }

    private func handleStateChange(_ state: GameState) {
        switch state {
        case .ready:
            return
        case .playing:
            updateLiveActivity(score: engine.score)
        case .paused:
            updatePausedActivity()
        case .gameOver:
            finishRun()
        }
    }

    private func updatePausedActivity() {
        Task {
            await runActivity.update(
                score: engine.score,
                bestScore: max(profile.bestScore, engine.score),
                streak: profile.dailyRunStreak,
                localRank: profile.localRank(for: engine.score),
                status: .paused
            )
        }
    }

    private func finishRun() {
        Task {
            await profile.record(score: engine.score, gemsEarned: engine.economy.gems)
            await runActivity.end(
                score: engine.score,
                bestScore: profile.bestScore,
                streak: profile.dailyRunStreak,
                localRank: profile.localRank(for: engine.score)
            )
        }
    }

    private func handleScenePhase(_ phase: ScenePhase) {
        switch phase {
        case .active:
            guard pausedByScenePhase, engine.state == .paused else { return }
            pausedByScenePhase = false
            engine.resume()
        case .inactive, .background:
            guard engine.state == .playing else { return }
            pausedByScenePhase = true
            engine.pause()
        @unknown default:
            return
        }
    }

    private func handleDisappear() {
        if engine.state == .playing { engine.pause() }
        Task {
            await runActivity.end(
                score: engine.score,
                bestScore: max(profile.bestScore, engine.score),
                streak: profile.dailyRunStreak,
                localRank: profile.localRank(for: engine.score)
            )
        }
    }
}