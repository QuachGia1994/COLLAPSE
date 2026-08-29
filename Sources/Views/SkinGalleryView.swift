import SwiftUI

@MainActor
struct SkinGalleryView: View {
    @Environment(PlayerProfile.self) private var profile
    @Environment(EntitlementStore.self) private var entitlement
    @State private var previewSkin: GameSkin = .classic
    @State private var showsPlus = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                skinPreview

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(GameSkin.allCases) { skin in
                        Button {
                            choose(skin)
                        } label: {
                            SkinCard(skin: skin, selected: profile.selectedSkin == skin, unlocked: isUnlocked(skin))
                        }
                        .buttonStyle(.plain)
                    }
                }

                if !entitlement.isPlusUnlocked {
                    Button("MỞ COLLAPSE PLUS") {
                        showsPlus = true
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.yellow)
                    .controlSize(.large)
                }
            }
            .padding(18)
        }
        .background(Color.black.ignoresSafeArea())
        .navigationTitle("Skin")
        .sheet(isPresented: $showsPlus) {
            PlusView()
        }
        .onAppear {
            previewSkin = profile.selectedSkin
        }
    }

    private var skinPreview: some View {
        let palette = previewSkin.palette
        return ZStack {
            LinearGradient(colors: [palette.backgroundTop, palette.backgroundBottom], startPoint: .topLeading, endPoint: .bottomTrailing)
            Circle()
                .stroke(palette.primary.opacity(0.65), lineWidth: 2)
                .frame(width: 190, height: 190)
            Capsule()
                .fill(palette.primary)
                .frame(width: 110, height: 3)
                .rotationEffect(.degrees(-14))
            Capsule()
                .fill(palette.secondary)
                .frame(width: 110, height: 3)
                .rotationEffect(.degrees(14))
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
        guard isUnlocked(skin) else {
            showsPlus = true
            return
        }
        profile.selectedSkin = skin
    }

    private func isUnlocked(_ skin: GameSkin) -> Bool {
        !skin.requiresPlus || entitlement.isPlusUnlocked
    }
}

private struct SkinCard: View {
    let skin: GameSkin
    let selected: Bool
    let unlocked: Bool

    var body: some View {
        let palette = skin.palette
        VStack(alignment: .leading, spacing: 10) {
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
                        .background(.ultraThinMaterial, in: Circle())
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        .padding(8)
                }
            }
            .frame(height: 128)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            Text(skin.title)
                .font(.subheadline.weight(.semibold))
            Text(skin.subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(10)
        .background(selected ? palette.primary.opacity(0.11) : Color.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(selected ? palette.primary.opacity(0.70) : .white.opacity(0.06), lineWidth: selected ? 1.5 : 1)
        }
    }
}
