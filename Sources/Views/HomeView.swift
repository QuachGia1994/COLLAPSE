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

                VStack(spacing: 26) {
                    Spacer()

                    logo
                    homeOrb

                    VStack(spacing: 12) {
                        NavigationLink {
                            GameView()
                        } label: {
                            Label("CHƠI", systemImage: "play.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(profile.selectedSkin.palette.primary)
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
                                Label(entitlement.isPlusUnlocked ? "PLUS" : "PLUS", systemImage: "diamond.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .tint(.yellow)
                        }
                    }
                    .frame(maxWidth: 360)

                    HStack(spacing: 24) {
                        metric(title: "KỶ LỤC", value: "\(profile.bestScore)")
                        metric(title: "DAILY", value: "🔥\(profile.dailyRunStreak)")
                        metric(title: "SKIN", value: profile.selectedSkin.title.uppercased())
                    }

                    Button("Xem lại hướng dẫn") {
                        showsTutorial = true
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                    Spacer(minLength: 22)
                }
                .padding(22)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .sheet(isPresented: $showsPlus) {
            PlusView()
        }
        .fullScreenCover(isPresented: $showsTutorial) {
            TutorialReplayView()
        }
    }

    private var background: some View {
        LinearGradient(
            colors: [profile.selectedSkin.palette.backgroundTop, profile.selectedSkin.palette.backgroundBottom],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
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
        let palette = profile.selectedSkin.palette
        return ZStack {
            Circle()
                .stroke(palette.primary.opacity(0.32), lineWidth: 2)
                .frame(width: 220, height: 220)
            Circle()
                .fill(palette.primary)
                .frame(width: 16, height: 16)
                .offset(x: -92)
            Circle()
                .fill(palette.safe)
                .frame(width: 17, height: 17)
                .offset(x: 90, y: -55)
            Circle()
                .stroke(palette.danger, lineWidth: 3)
                .frame(width: 22, height: 22)
                .offset(x: 72, y: 62)
            pathLine(color: palette.primary, rotation: -17)
            pathLine(color: palette.secondary, rotation: 20)
        }
        .frame(height: 240)
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
                .tracking(2)
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
