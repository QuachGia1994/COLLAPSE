import SwiftUI

@MainActor
struct GameView: View {
    @Environment(PlayerProfile.self) private var profile
    @Environment(SensoryEngine.self) private var sensory
    @Environment(RunActivityController.self) private var runActivity
    @Environment(\.scenePhase) private var scenePhase
    @State private var engine = GameEngine()
    @State private var pausedByScenePhase = false

    var body: some View {
        ZStack {
            GameBoardView(engine: engine, skin: profile.selectedSkin)
                .ignoresSafeArea()

            hud

            if engine.state == .paused {
                pauseCard
            }

            if engine.state == .gameOver {
                deathCard
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            engine.connectSensory(sensory.client)
            profile.registerRunStart()
            engine.start()
            await runActivity.start(
                streak: profile.dailyRunStreak,
                bestScore: profile.bestScore,
                localRank: profile.localRank(for: engine.score)
            )
        }
        .onChange(of: engine.score) { _, score in
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
        .onChange(of: engine.state) { _, state in
            handleStateChange(state)
        }
        .onChange(of: scenePhase) { _, phase in
            handleScenePhase(phase)
        }
        .onDisappear {
            if engine.state == .playing {
                engine.pause()
            }
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

    private var hud: some View {
        VStack {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 7) {
                    Text("COLLAPSE")
                        .font(.caption.weight(.medium))
                        .tracking(4)
                        .foregroundStyle(.white.opacity(0.72))
                    Label("DỰ BÁO \(engine.choiceDuration, format: .number.precision(.fractionLength(1)))s", systemImage: "eye")
                        .font(.caption2.monospaced().weight(.semibold))
                        .foregroundStyle(profile.selectedSkin.palette.primary)
                    Text("🔥 \(profile.dailyRunStreak) ngày")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.white.opacity(0.58))
                }

                Spacer()

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
            .padding(.horizontal, 20)
            .padding(.top, 14)

            Spacer()

            if engine.phase == .choosing, engine.state == .playing {
                HStack(spacing: 8) {
                    Circle()
                        .fill(engine.guidanceQuality > 0.5 ? Color.green : Color.red)
                        .frame(width: 7, height: 7)
                    Text("CHẠM ĐỂ ĐỔI TƯƠNG LAI")
                }
                .font(.caption.weight(.semibold))
                .tracking(1.4)
                .foregroundStyle(.white.opacity(0.76))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial, in: Capsule())
                .padding(.bottom, 24)
                .allowsHitTesting(false)
            }
        }
    }

    private var pauseCard: some View {
        VStack(spacing: 14) {
            Image(systemName: "pause.circle.fill")
                .font(.system(size: 38))
                .foregroundStyle(profile.selectedSkin.palette.primary)
            Text("TẠM DỪNG")
                .font(.headline)
                .tracking(2)
            Button("TIẾP TỤC") {
                engine.resume()
            }
            .buttonStyle(.borderedProminent)
            .tint(profile.selectedSkin.palette.primary)
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
            HStack(spacing: 22) {
                stat("ĐIỂM", value: "\(engine.score)")
                stat("KỶ LỤC", value: "\(profile.bestScore)")
                stat("HẠNG", value: profile.localRank(for: engine.score).map { "#\($0)" } ?? "—")
            }
            Button("THỬ TƯƠNG LAI KHÁC") {
                engine.restart()
                Task {
                    await runActivity.start(
                        streak: profile.dailyRunStreak,
                        bestScore: profile.bestScore,
                        localRank: profile.localRank(for: 0)
                    )
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(profile.selectedSkin.palette.primary)
        }
        .padding(24)
        .frame(maxWidth: 350)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(.white.opacity(0.10), lineWidth: 1)
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

    private func handleStateChange(_ state: GameState) {
        switch state {
        case .ready:
            return
        case .playing:
            Task {
                await runActivity.update(
                    score: engine.score,
                    bestScore: max(profile.bestScore, engine.score),
                    streak: profile.dailyRunStreak,
                    localRank: profile.localRank(for: engine.score),
                    status: .playing
                )
            }
        case .paused:
            Task {
                await runActivity.update(
                    score: engine.score,
                    bestScore: max(profile.bestScore, engine.score),
                    streak: profile.dailyRunStreak,
                    localRank: profile.localRank(for: engine.score),
                    status: .paused
                )
            }
        case .gameOver:
            profile.record(score: engine.score)
            Task {
                await runActivity.end(
                    score: engine.score,
                    bestScore: profile.bestScore,
                    streak: profile.dailyRunStreak,
                    localRank: profile.localRank(for: engine.score)
                )
            }
        }
    }

    private func handleScenePhase(_ phase: ScenePhase) {
        switch phase {
        case .active:
            if pausedByScenePhase, engine.state == .paused {
                pausedByScenePhase = false
                engine.resume()
            }
        case .inactive, .background:
            if engine.state == .playing {
                pausedByScenePhase = true
                engine.pause()
            }
        @unknown default:
            return
        }
    }
}
