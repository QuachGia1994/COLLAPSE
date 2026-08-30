import SwiftUI

@MainActor
struct HomeView: View {
    @Environment(PlayerProfile.self) private var profile
    @Environment(EntitlementStore.self) private var entitlement
    @Environment(GameCenterStore.self) private var gameCenter
    @State private var showsPlus = false
    @State private var showsTutorial = false

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                ZStack {
                    background
                    glassBackdrop
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 16) {
                            header
                            homeOrb
                            modePicker
                            actionCard
                            metricsCard
                        }
                        .frame(maxWidth: 410)
                        .frame(minHeight: proxy.size.height, alignment: .center)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .sheet(isPresented: $showsPlus) { PlusView() }
        .fullScreenCover(isPresented: $showsTutorial) { TutorialView(isReplay: true) }
        .task(id: profile.selectedMode) {
            await gameCenter.refresh(mode: profile.selectedMode)
        }
    }

    private var language: AppLanguage { profile.selectedLanguage }

    private var activeSkin: GameSkin {
        profile.activeSkin(isPlusUnlocked: entitlement.isPlusUnlocked)
    }

    private var header: some View {
        HStack(spacing: 12) {
            CollapseBrandMark(
                tint: activeSkin.palette.primary,
                subtitle: language.text("brand.subtitle"),
                compact: true
            )
            Spacer(minLength: 8)
            tutorialQuickButton
            languageMenu
        }
        .frame(maxWidth: 380)
    }

    private var tutorialQuickButton: some View {
        Button { showsTutorial = true } label: {
            Image(systemName: "questionmark")
                .font(.caption.weight(.bold))
                .frame(width: 42, height: 42)
                .background(.thinMaterial, in: Circle())
                .overlay { Circle().stroke(.white.opacity(0.14), lineWidth: 1) }
        }
        .accessibilityLabel(language.text("home.tutorial"))
        .accessibilityIdentifier("home.tutorial.quick")
    }

    private var languageMenu: some View {
        Menu {
            ForEach(AppLanguage.allCases) { item in
                Button {
                    profile.selectedLanguage = item
                } label: {
                    if profile.selectedLanguage == item {
                        Label(item.displayName, systemImage: "checkmark")
                    } else {
                        Text(item.displayName)
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "globe")
                Text(language.shortLabel)
                    .font(.caption.weight(.semibold))
            }
            .frame(minWidth: 58, minHeight: 42)
            .padding(.horizontal, 8)
            .background(.thinMaterial, in: Capsule())
            .overlay { Capsule().stroke(.white.opacity(0.14), lineWidth: 1) }
        }
        .accessibilityLabel(language.text("home.language"))
        .accessibilityIdentifier("home.language")
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
                glassCircle(
                    diameter: min(proxy.size.width * 0.78, 320),
                    x: -proxy.size.width * 0.32,
                    y: -proxy.size.height * 0.30,
                    opacity: 0.22
                )
                glassCircle(
                    diameter: min(proxy.size.width * 0.68, 280),
                    x: proxy.size.width * 0.34,
                    y: proxy.size.height * 0.32,
                    opacity: 0.16
                )
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
            Circle().fill(.thinMaterial)
            Circle()
                .stroke(palette.primary.opacity(0.38), lineWidth: 2)
                .padding(2)
            Circle().fill(palette.primary).frame(width: 16, height: 16).offset(x: -92)
            Circle().fill(palette.safe).frame(width: 17, height: 17).offset(x: 90, y: -55)
            Circle().stroke(palette.danger, lineWidth: 3).frame(width: 22, height: 22).offset(x: 72, y: 62)
            pathLine(color: palette.primary, rotation: -17)
            pathLine(color: palette.secondary, rotation: 20)
        }
        .frame(width: 214, height: 214)
        .accessibilityHidden(true)
    }

    private var modePicker: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("\(language.text("home.mode")) · \(profile.selectedMode.title)")
                .font(.caption.weight(.semibold))
                .tracking(1.5)
            Text(profile.selectedMode.subtitle(language: language))
                .font(.caption)
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(GameMode.allCases) { mode in
                        Button(mode.title) { profile.selectedMode = mode }
                            .buttonStyle(.bordered)
                            .buttonBorderShape(.capsule)
                            .tint(profile.selectedMode == mode ? activeSkin.palette.primary : Color.gray)
                    }
                }
            }
        }
        .padding(13)
        .frame(maxWidth: 380)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay { glassBorder(cornerRadius: 22) }
    }

    private var actionCard: some View {
        VStack(spacing: 10) {
            NavigationLink { GameView(mode: profile.selectedMode) } label: {
                Label(language.text("home.play"), systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(activeSkin.palette.primary)
            .controlSize(.large)

            HStack(spacing: 10) {
                NavigationLink { SkinGalleryView() } label: {
                    Label(language.text("home.skin"), systemImage: "circle.hexagongrid")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button { showsPlus = true } label: {
                    Label(
                        language.text("home.plus"),
                        systemImage: entitlement.isPlusUnlocked ? "checkmark.seal.fill" : "diamond.fill"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.yellow)
            }

            Button { showsTutorial = true } label: {
                Label(language.text("home.tutorial"), systemImage: "questionmark.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("home.tutorial")
        }
        .padding(13)
        .frame(maxWidth: 380)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay { glassBorder(cornerRadius: 24) }
    }

    private var metricsCard: some View {
        VStack(spacing: 10) {
            HStack {
                Text("\(profile.selectedMode.title) · \(language.text("home.stats"))")
                    .font(.caption.weight(.semibold))
                    .tracking(1.4)
                Spacer()
                rankBadge
            }

            HStack(spacing: 6) {
                metric(title: language.text("home.best"), value: "\(profile.bestScore(for: profile.selectedMode))")
                metric(title: language.text("home.today"), value: "\(profile.dailyBestScore(for: profile.selectedMode))")
                metric(title: language.text("home.streak"), value: "🔥\(profile.dailyRunStreak)")
                metric(title: language.text("home.gems"), value: "◆\(profile.gemBalance)")
            }

            Text(String(format: language.text("home.account"), profile.selectedMode.title))
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .frame(maxWidth: 380)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay { glassBorder(cornerRadius: 22) }
    }

    @ViewBuilder
    private var rankBadge: some View {
        if !profile.selectedMode.isCompetitive {
            Text("ZEN · LOCAL")
                .font(.caption2.monospaced().weight(.semibold))
                .foregroundStyle(.secondary)
        } else if let rank = gameCenter.remoteRank(for: profile.selectedMode) {
            Text(String(format: language.text("home.rank.gamecenter"), rank))
                .font(.caption2.monospaced().weight(.semibold))
                .foregroundStyle(.green)
        } else if let localRank = profile.localRank(
            for: profile.bestScore(for: profile.selectedMode),
            mode: profile.selectedMode
        ) {
            Text(String(format: language.text("home.rank.local"), localRank))
                .font(.caption2.monospaced().weight(.semibold))
                .foregroundStyle(activeSkin.palette.primary)
        } else {
            Button(language.text("home.rank.connect")) { gameCenter.start() }
                .font(.caption2.weight(.semibold))
                .buttonStyle(.borderless)
        }
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
                .minimumScaleFactor(0.72)
            Text(title)
                .font(.caption2)
                .tracking(1.0)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.68)
        }
        .frame(maxWidth: .infinity)
    }

    private func glassBorder(cornerRadius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .stroke(.white.opacity(0.10), lineWidth: 1)
    }
}
