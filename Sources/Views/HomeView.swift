import SwiftUI

@MainActor
struct HomeView: View {
    @Environment(PlayerProfile.self) private var profile
    @Environment(EntitlementStore.self) private var entitlement
    @State private var showsPlus = false
    @State private var showsTutorial = false

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                ZStack {
                    background
                    glassBackdrop
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 20) {
                            CollapseBrandMark(tint: activeSkin.palette.primary)
                            homeOrb
                            actionCard
                            metricsCard
                            tutorialButton
                        }
                        .frame(maxWidth: 410)
                        .frame(minHeight: proxy.size.height, alignment: .center)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 18)
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .sheet(isPresented: $showsPlus) { PlusView() }
        .fullScreenCover(isPresented: $showsTutorial) { TutorialView(isReplay: true) }
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
        GeometryReader { proxy in
            ZStack {
                glassCircle(diameter: min(proxy.size.width * 0.78, 320), x: -proxy.size.width * 0.32, y: -proxy.size.height * 0.30, opacity: 0.22)
                glassCircle(diameter: min(proxy.size.width * 0.68, 280), x: proxy.size.width * 0.34, y: proxy.size.height * 0.32, opacity: 0.16)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private func glassCircle(diameter: CGFloat, x: CGFloat, y: CGFloat, opacity: Double) -> some View {
        Circle()
            .fill(.thinMaterial)
            .frame(width: diameter, height: diameter)
            .offset(x: x, y: y)
            .opacity(opacity)
    }

    private var homeOrb: some View {
        let palette = activeSkin.palette
        return ZStack {
            Circle()
                .fill(.thinMaterial)
            Circle()
                .stroke(palette.primary.opacity(0.38), lineWidth: 2)
                .padding(2)
            Circle().fill(palette.primary).frame(width: 16, height: 16).offset(x: -92)
            Circle().fill(palette.safe).frame(width: 17, height: 17).offset(x: 90, y: -55)
            Circle().stroke(palette.danger, lineWidth: 3).frame(width: 22, height: 22).offset(x: 72, y: 62)
            pathLine(color: palette.primary, rotation: -17)
            pathLine(color: palette.secondary, rotation: 20)
        }
        .frame(width: 224, height: 224)
        .accessibilityHidden(true)
    }

    private var actionCard: some View {
        VStack(spacing: 12) {
            NavigationLink { GameView() } label: {
                Label("CHƠI", systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(activeSkin.palette.primary)
            .controlSize(.large)

            HStack(spacing: 10) {
                NavigationLink { SkinGalleryView() } label: {
                    Label("SKIN", systemImage: "circle.hexagongrid")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button { showsPlus = true } label: {
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
        .overlay { glassBorder(cornerRadius: 26) }
    }

    private var metricsCard: some View {
        HStack(spacing: 6) {
            metric(title: "KỶ LỤC", value: "\(profile.bestScore)")
            metric(title: "HÔM NAY", value: "\(profile.dailyBestScore)")
            metric(title: "STREAK", value: "🔥\(profile.dailyRunStreak)")
            metric(title: "GEM", value: "◆\(profile.gemBalance)")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 14)
        .frame(maxWidth: 380)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay { glassBorder(cornerRadius: 24) }
    }

    private var tutorialButton: some View {
        Button("Xem lại hướng dẫn") { showsTutorial = true }
            .font(.footnote.weight(.medium))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background(.thinMaterial, in: Capsule())
            .accessibilityIdentifier("home.tutorial")
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
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(title)
                .font(.caption2)
                .tracking(1.2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity)
    }

    private func glassBorder(cornerRadius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .stroke(.white.opacity(0.10), lineWidth: 1)
    }
}