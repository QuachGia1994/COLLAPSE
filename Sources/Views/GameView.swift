import SwiftUI

@MainActor
struct GameView: View {
    let mode: GameMode

    @Environment(PlayerProfile.self) private var profile
    @Environment(EntitlementStore.self) private var entitlement
    @Environment(SensoryEngine.self) private var sensory
    @Environment(RunActivityController.self) private var runActivity
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dismiss) private var dismiss
    @State private var engine: GameEngine
    @State private var pausedByScenePhase = false
    @State private var isFinalizingRun = false

    init(mode: GameMode) {
        self.mode = mode
        _engine = State(initialValue: GameEngine(mode: mode))
    }

    var body: some View {
        ZStack {
            GameBoardView(engine: engine, skin: activeSkin)
                .ignoresSafeArea()
            hud
            if engine.phase == .ready, engine.state == .playing { countdownOverlay }
            if engine.state == .paused { overlayBackground }
            if engine.state == .gameOver { overlayBackground }
            if engine.state == .paused { pauseCard }
            if engine.state == .gameOver { deathCard }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task { startRun() }
        .onChange(of: engine.score) { _, score in syncLiveActivity(score: score) }
        .onChange(of: engine.phase) { _, phase in
            if phase == .choosing { syncLiveActivity(score: engine.score) }
        }
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
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private var topHUD: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                CollapseBrandMark(tint: activeSkin.palette.primary, subtitle: "", compact: true)
                Text(mode.title)
                    .font(.caption2.weight(.semibold))
                    .tracking(1.5)
                    .foregroundStyle(.secondary)
                Label("DỰ BÁO \(engine.choiceDuration, format: .number.precision(.fractionLength(1)))s", systemImage: "eye")
                    .font(.caption2.monospaced().weight(.semibold))
                    .foregroundStyle(activeSkin.palette.primary)
                Text("🔥 \(profile.dailyRunStreak) ngày  ·  ◆ \(profile.gemBalance + engine.economy.gems)")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.white.opacity(0.64))
            }
            Spacer(minLength: 8)
            scoreBlock
            pauseButton
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay { glassBorder(cornerRadius: 24) }
    }

    private var scoreBlock: some View {
        VStack(spacing: 2) {
            Text("\(engine.score)")
                .font(.system(size: 34, weight: .semibold, design: .rounded))
                .monospacedDigit()
            Text("ĐIỂM")
                .font(.caption2)
                .tracking(1.6)
                .foregroundStyle(.secondary)
        }
        .frame(minWidth: 54)
    }

    private var pauseButton: some View {
        Button { engine.pause() } label: {
            Image(systemName: "pause.fill")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(activeSkin.palette.primary)
                .frame(width: 44, height: 44)
                .background(.thinMaterial, in: Circle())
                .overlay { Circle().stroke(.white.opacity(0.24), lineWidth: 1) }
        }
        .buttonStyle(.plain)
        .frame(width: 48, height: 48, alignment: .center)
        .opacity(engine.state == .playing && engine.phase != .ready ? 1 : 0)
        .disabled(engine.state != .playing || engine.phase == .ready)
        .accessibilityLabel("Tạm dừng")
        .accessibilityIdentifier("game.pause")
    }

    private var countdownOverlay: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            ZStack {
                Circle()
                    .fill(.thinMaterial)
                    .frame(width: 118, height: 118)
                    .overlay { Circle().stroke(activeSkin.palette.primary.opacity(0.32), lineWidth: 1.5) }
                Text(engine.countdownLabel(at: time) ?? "")
                    .font(.system(size: 50, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
            }
            .transition(.scale.combined(with: .opacity))
            .allowsHitTesting(false)
            .accessibilityLabel("Bắt đầu sau \(engine.countdownLabel(at: time) ?? "")")
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
        .tracking(1.3)
        .foregroundStyle(.white.opacity(0.82))
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.regularMaterial, in: Capsule())
        .overlay { Capsule().stroke(.white.opacity(0.10), lineWidth: 1) }
        .padding(.bottom, 12)
        .allowsHitTesting(false)
    }

    private var overlayBackground: some View {
        Color.black.opacity(0.42)
            .ignoresSafeArea()
            .transition(.opacity)
    }

    private var pauseCard: some View {
        VStack(spacing: 16) {
            CollapseBrandMark(tint: activeSkin.palette.primary, subtitle: "TẠM DỪNG", compact: true)
            Button("TIẾP TỤC") { engine.resume() }
                .buttonStyle(.borderedProminent)
                .tint(activeSkin.palette.primary)
                .controlSize(.large)
                .accessibilityIdentifier("game.resume")
            HStack(spacing: 10) {
                Button("CHƠI LẠI") { restartRun() }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("game.pause.restart")
                Button("VỀ TRANG CHỦ") { leaveGame() }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("game.pause.home")
            }
        }
        .padding(22)
        .frame(maxWidth: 340)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay { glassBorder(cornerRadius: 28) }
        .padding(24)
    }

    private var deathCard: some View {
        VStack(spacing: 15) {
            CollapseBrandMark(tint: activeSkin.palette.danger, subtitle: "DÒNG THỜI GIAN ĐÃ VỠ", compact: true)
            Text("Dự báo đã cho thấy tương lai này đi xuyên vùng đỏ.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            HStack(spacing: 18) {
                stat("ĐIỂM", value: "\(engine.score)")
                stat("GEM", value: "+\(engine.economy.gems)")
                stat("KỶ LỤC", value: "\(max(profile.bestScore, engine.score))")
            }
            if isFinalizingRun {
                ProgressView("Đang lưu lượt chơi…")
                    .font(.caption)
            }
            Button("CHƠI LẠI") { restartRun() }
                .buttonStyle(.borderedProminent)
                .tint(activeSkin.palette.primary)
                .controlSize(.large)
                .disabled(isFinalizingRun)
                .accessibilityIdentifier("game.over.restart")
            Button("VỀ TRANG CHỦ") { leaveGame() }
                .buttonStyle(.bordered)
                .disabled(isFinalizingRun)
                .accessibilityIdentifier("game.over.home")
        }
        .padding(22)
        .frame(maxWidth: 360)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay { glassBorder(cornerRadius: 28) }
        .padding(24)
    }

    private func stat(_ title: String, value: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.title3.monospacedDigit().weight(.semibold))
            Text(title)
                .font(.caption2)
                .tracking(1.4)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func startRun() {
        engine.connectSensory(sensory.client)
        profile.registerRunStart()
        engine.start()
    }

    private func startLiveActivity() async {
        guard mode.isCompetitive else { return }
        guard scenePhase == .active, engine.state == .playing, engine.phase != .ready else { return }
        await runActivity.start(
            score: engine.score,
            streak: profile.dailyRunStreak,
            bestScore: max(profile.bestScore, engine.score),
            localRank: profile.localRank(for: engine.score)
        )
    }

    private func syncLiveActivity(score: Int) {
        guard mode.isCompetitive else { return }
        guard scenePhase == .active, engine.state == .playing, engine.phase != .ready else { return }
        Task {
            if runActivity.isActive {
                await runActivity.update(
                    score: score,
                    bestScore: max(profile.bestScore, score),
                    streak: profile.dailyRunStreak,
                    localRank: profile.localRank(for: score),
                    status: .playing
                )
                return
            }
            await startLiveActivity()
        }
    }

    private func handleStateChange(_ state: GameState) {
        switch state {
        case .ready:
            return
        case .playing:
            syncLiveActivity(score: engine.score)
        case .paused:
            guard !pausedByScenePhase else { return }
            updatePausedActivity()
        case .gameOver:
            finalizeRun()
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

    private func finalizeRun() {
        guard !isFinalizingRun else { return }
        isFinalizingRun = true
        Task {
            await endLiveActivity()
            if mode.isCompetitive {
                await profile.record(score: engine.score, gemsEarned: engine.economy.gems)
            }
            isFinalizingRun = false
        }
    }

    private func restartRun() {
        guard !isFinalizingRun else { return }
        profile.registerRunStart()
        engine.restart()
    }

    private func leaveGame() {
        guard !isFinalizingRun else { return }
        Task {
            await endLiveActivity()
            dismiss()
        }
    }

    private func handleScenePhase(_ phase: ScenePhase) {
        switch phase {
        case .active:
            resumeAfterSceneActivation()
        case .inactive:
            pauseForSceneDeactivation()
            Task { await endLiveActivity() }
        case .background:
            Task { await endLiveActivity() }
        @unknown default:
            return
        }
    }

    private func pauseForSceneDeactivation() {
        guard engine.state == .playing else { return }
        pausedByScenePhase = true
        engine.pause()
    }

    private func resumeAfterSceneActivation() {
        guard pausedByScenePhase, engine.state == .paused else { return }
        pausedByScenePhase = false
        engine.resume()
    }

    private func handleDisappear() {
        if engine.state == .playing {
            pausedByScenePhase = true
            engine.pause()
        }
        Task { await endLiveActivity() }
    }

    private func endLiveActivity() async {
        await runActivity.end(
            score: engine.score,
            bestScore: max(profile.bestScore, engine.score),
            streak: profile.dailyRunStreak,
            localRank: profile.localRank(for: engine.score)
        )
    }

    private func glassBorder(cornerRadius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .stroke(.white.opacity(0.12), lineWidth: 1)
    }
}