import SwiftUI

@MainActor
struct GameView: View {
    @Environment(PlayerProfile.self) private var profile
    @State private var session = GameSession()

    var body: some View {
        ZStack {
            GameBoardView(session: session, skin: profile.selectedSkin)
                .ignoresSafeArea()

            hud

            if session.phase == .dead {
                deathCard
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            session.start()
            while !Task.isCancelled {
                session.tick()
                try? await Task.sleep(for: .milliseconds(16))
            }
        }
        .onChange(of: session.phase) { _, phase in
            if phase == .dead {
                profile.record(score: session.score)
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
                    Label("DỰ BÁO \(session.choiceDuration, format: .number.precision(.fractionLength(1)))s", systemImage: "eye")
                        .font(.caption2.monospaced().weight(.semibold))
                        .foregroundStyle(profile.selectedSkin.palette.primary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(session.score)")
                        .font(.system(size: 38, weight: .semibold, design: .rounded))
                    Text("ĐIỂM")
                        .font(.caption2)
                        .tracking(2)
                        .foregroundStyle(.white.opacity(0.50))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)

            Spacer()

            if session.phase == .choosing {
                Text("CHẠM ĐỂ ĐỔI TƯƠNG LAI")
                    .font(.caption.weight(.semibold))
                    .tracking(1.5)
                    .foregroundStyle(.white.opacity(0.72))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(.bottom, 24)
            }
        }
        .allowsHitTesting(false)
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
                stat("ĐIỂM", value: "\(session.score)")
                stat("KỶ LỤC", value: "\(profile.bestScore)")
            }
            Button("THỬ TƯƠNG LAI KHÁC") {
                session.restart()
            }
            .buttonStyle(.borderedProminent)
            .tint(profile.selectedSkin.palette.primary)
        }
        .padding(24)
        .frame(maxWidth: 330)
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
                .font(.title2.monospacedDigit().weight(.semibold))
            Text(title)
                .font(.caption2)
                .tracking(2)
                .foregroundStyle(.secondary)
        }
    }
}
