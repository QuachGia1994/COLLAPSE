import SwiftUI

@MainActor
struct HomeView: View {
    @Environment(PlayerProfile.self) private var profile
    @Environment(EntitlementStore.self) private var entitlement
    @State private var showsPlus = false
    @State private var showsTutorial = false

    var body: some View {
        NavigationStack {
            ZStack {
                background
                glassBackdrop
                VStack(spacing: 24) {
                    Spacer()
                    logo
                    homeOrb
                    actionCard
                    metricsCard
                    Button("Xem lại hướng dẫn") { showsTutorial = true }
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Spacer(minLength: 22)
                }
                .padding(22)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .sheet(isPresented: $showsPlus) { PlusView() }
        .fullScreenCover(isPresented: $showsTutorial) { TutorialReplayView() }
    }

    private var activeSkin: GameSkin {
        profile.activeSkin(isPlusUnlocked: entitlement.isPlusUnlocked)
    }

    private var background: some View {
        LinearGradient(
            colors: [activeSkin.palette.backgroundTop, activeSkin.palette.backgroundBottom],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private var glassBackdrop: some View {
        ZStack {
            Circle()
                .fill(.thinMaterial)
                .frame(width: 320, height: 320)
                .offset(x: -140, y: -270)
                .opacity(0.24)
            Circle()
                .fill(.regularMaterial)
                .frame(width: 280, height: 280)
                .offset(x: 150, y: 290)
                .opacity(0.18)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private var logo: some View {
        VStack(spacing: 8) {
            Text("COLLAPSE")
                .font(.system(size: 38, weight: .light, design: .rounded))
                .tracking(8)
            Text("CHỌN TƯƠNG LAI")
                .font(.caption2.weight(.medium))
                .tracking(3)
                .foregroundStyle(.secondary)
        }
    }

    private var homeOrb: some View {
        let palette = activeSkin.palette
        return ZStack {
            Circle()
                .fill(.thinMaterial)
                .frame(width: 224, height: 224)
            Circle()
                .stroke(palette.primary.opacity(0.34), lineWidth: 2)
                .frame(width: 220, height: 220)
            Circle().fill(palette.primary).frame(width: 16, height: 16).offset(x: -92)
            Circle().fill(palette.safe).frame(width: 17, height: 17).offset(x: 90, y: -55)
            Circle().stroke(palette.danger, lineWidth: 3).frame(width: 22, height: 22).offset(x: 72, y: 62)
            pathLine(color: palette.primary, rotation: -17)
            pathLine(color: palette.secondary, rotation: 20)
        }
        .frame(height: 240)
    }

    private var actionCard: some View {
        VStack(spacing: 12) {
            NavigationLink {
                GameView()
            } label: {
                Label("CHƠI", systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(activeSkin.palette.primary)
            .controlSize(.large)

            HStack(spacing: 10) {
                NavigationLink {
                    SkinGalleryView()
                } label: {
                    Label("SKIN", systemImage: "circle.hexagongrid")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    showsPlus = true
                } label: {
                    Label("PLUS", systemImage: entitlement.isPlusUnlocked ? "checkmark.seal.fill" : "diamond.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.yellow)
            }
        }
        .padding(14)
        .frame(maxWidth: 380)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(.white.opacity(0.10), lineWidth: 1)
        }
    }

    private var metricsCard: some View {
        HStack(spacing: 20) {
            metric(title: "KỶ LỤC", value: "\(profile.bestScore)")
            metric(title: "HÔM NAY", value: "\(profile.dailyBestScore)")
            metric(title: "STREAK", value: "🔥\(profile.dailyRunStreak)")
            metric(title: "GEM", value: "◆\(profile.gemBalance)")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.thinMaterial, in: Capsule())
    }

    private func pathLine(color: Color, rotation: Double) -> some View {
        Capsule()
            .fill(color.opacity(0.88))
            .frame(width: 150, height: 3)
            .rotationEffect(.degrees(rotation))
    }

    private func metric(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.subheadline.monospacedDigit().weight(.semibold))
            Text(title)
                .font(.caption2)
                .tracking(1.4)
                .foregroundStyle(.secondary)
        }
    }
}

@MainActor
private struct TutorialReplayView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .topTrailing) {
            TutorialPreviewPager()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.72))
            }
            .padding(20)
        }
    }
}

private struct TutorialPreviewPager: View {
    @State private var page = 0

    var body: some View {
        TabView(selection: $page) {
            tutorialPage("Nhìn 2 tương lai", "Hai đường cho biết trước kết quả.", "eye").tag(0)
            tutorialPage("Chạm để đổi nhánh", "Một chạm đổi lựa chọn.", "hand.tap").tag(1)
            tutorialPage("Chốt lựa chọn", "Hết thời gian, tương lai đã chọn thành hiện thực.", "checkmark.circle").tag(2)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .background(Color.black.ignoresSafeArea())
    }

    private func tutorialPage(_ title: String, _ detail: String, _ symbol: String) -> some View {
        VStack(spacing: 22) {
            Spacer()
            Image(systemName: symbol)
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(.cyan)
            Text(title)
                .font(.title2.weight(.semibold))
            Text(detail)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(28)
    }
}