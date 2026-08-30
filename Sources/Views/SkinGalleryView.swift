import SwiftUI

@MainActor
struct SkinGalleryView: View {
    @Environment(PlayerProfile.self) private var profile
    @Environment(EntitlementStore.self) private var entitlement
    @State private var previewSkin: GameSkin = .classic
    @State private var showsPlus = false
    @State private var showsInsufficientGems = false

    private var language: AppLanguage { profile.selectedLanguage }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                skinPreview
                balanceChip
                skinGrid

                if !entitlement.isPlusUnlocked {
                    Button(language.text("skin.openPlus")) { showsPlus = true }
                        .buttonStyle(.borderedProminent)
                        .tint(.yellow)
                        .controlSize(.large)
                }
            }
            .padding(18)
        }
        .background(Color.black.ignoresSafeArea())
        .navigationTitle(language.text("skin.title"))
        .sheet(isPresented: $showsPlus) { PlusView() }
        .alert(language.text("skin.insufficient.title"), isPresented: $showsInsufficientGems) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(language.text("skin.insufficient.message"))
        }
        .onAppear { previewSkin = profile.activeSkin(isPlusUnlocked: entitlement.isPlusUnlocked) }
    }

    private var skinGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(GameSkin.allCases) { skin in
                Button {
                    choose(skin)
                } label: {
                    SkinCard(
                        skin: skin,
                        selected: profile.selectedSkin == skin,
                        unlocked: isUnlocked(skin),
                        language: language
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var balanceChip: some View {
        Label("\(profile.gemBalance) \(language.text("skin.gems"))", systemImage: "diamond.fill")
            .font(.subheadline.monospacedDigit().weight(.semibold))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.thinMaterial, in: Capsule())
    }

    private var skinPreview: some View {
        let palette = previewSkin.palette
        return ZStack {
            LinearGradient(colors: [palette.backgroundTop, palette.backgroundBottom], startPoint: .topLeading, endPoint: .bottomTrailing)
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(.thinMaterial)
                .opacity(0.22)
            Circle()
                .stroke(palette.primary.opacity(0.65), lineWidth: 2)
                .frame(width: 190, height: 190)
            Capsule().fill(palette.primary).frame(width: 110, height: 3).rotationEffect(.degrees(-14))
            Capsule().fill(palette.secondary).frame(width: 110, height: 3).rotationEffect(.degrees(14))
            Circle().fill(palette.safe).frame(width: 17, height: 17).offset(x: 72)
            Circle().stroke(palette.danger, lineWidth: 3).frame(width: 22, height: 22).offset(x: 48, y: 49)
            VStack {
                Spacer()
                Text(previewSkin.title.uppercased())
                    .font(.caption.weight(.semibold))
                    .tracking(3)
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.bottom, 16)
            }
        }
        .frame(height: 260)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(palette.primary.opacity(0.22), lineWidth: 1)
        }
    }

    private func choose(_ skin: GameSkin) {
        previewSkin = skin
        if isUnlocked(skin) {
            profile.selectedSkin = skin
            return
        }

        switch skin.access {
        case .free:
            profile.selectedSkin = skin
        case .gems:
            guard profile.unlock(skin) else {
                showsInsufficientGems = true
                return
            }
            profile.selectedSkin = skin
        case .plus:
            showsPlus = true
        }
    }

    private func isUnlocked(_ skin: GameSkin) -> Bool {
        profile.isUnlocked(skin, isPlusUnlocked: entitlement.isPlusUnlocked)
    }
}

private struct SkinCard: View {
    let skin: GameSkin
    let selected: Bool
    let unlocked: Bool
    let language: AppLanguage

    var body: some View {
        let palette = skin.palette
        VStack(alignment: .leading, spacing: 10) {
            preview(palette: palette)
            Text(skin.title)
                .font(.subheadline.weight(.semibold))
            HStack {
                Text(language.text(skinDetailKey))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(accessLabel)
                    .font(.caption2.monospacedDigit().weight(.semibold))
                    .foregroundStyle(unlocked ? .green : .yellow)
            }
        }
        .padding(10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(selected ? palette.primary.opacity(0.70) : .white.opacity(0.08), lineWidth: selected ? 1.5 : 1)
        }
    }

    private func preview(palette: SkinPalette) -> some View {
        ZStack {
            LinearGradient(colors: [palette.backgroundTop, palette.backgroundBottom], startPoint: .topLeading, endPoint: .bottomTrailing)
            Circle()
                .stroke(palette.primary.opacity(0.72), lineWidth: 2)
                .frame(width: 88, height: 88)
            HStack(spacing: 28) {
                Circle().fill(palette.primary).frame(width: 9, height: 9)
                Circle().fill(palette.safe).frame(width: 9, height: 9)
            }
            if !unlocked {
                Image(systemName: "lock.fill")
                    .font(.caption)
                    .padding(8)
                    .background(.thinMaterial, in: Circle())
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(8)
            }
        }
        .frame(height: 128)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var skinDetailKey: String {
        switch skin {
        case .classic: "skin.classic.detail"
        case .nebula: "skin.nebula.detail"
        case .aurora: "skin.aurora.detail"
        case .solar: "skin.solar.detail"
        case .obsidian: "skin.obsidian.detail"
        case .frozenQuartz: "skin.frozen.detail"
        }
    }

    private var accessLabel: String {
        guard !unlocked else { return language.text("skin.unlocked") }
        switch skin.access {
        case .free:
            return "FREE"
        case .gems(let cost):
            return "◆\(cost)"
        case .plus:
            return "PLUS"
        }
    }
}