import SwiftUI

@MainActor
struct GameBoardView: View {
    let engine: GameEngine
    let skin: GameSkin
    @State private var budgetMonitor = RenderBudgetMonitor()

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
            let timestamp = timeline.date.timeIntervalSinceReferenceDate
            let snapshot = GameRenderSnapshot(engine: engine, time: timestamp)
            ZStack {
                background
                ambientGlass
                Canvas { context, size in
                    CollapseCanvasRenderer.draw(
                        context: &context,
                        size: size,
                        snapshot: snapshot,
                        skin: skin,
                        time: timestamp
                    )
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                engine.toggleSelection()
            }
            .onChange(of: timeline.date) { _, date in
                let frameTime = date.timeIntervalSinceReferenceDate
                budgetMonitor.record(timestamp: frameTime)
                engine.tick(at: frameTime)
            }
        }
        .accessibilityLabel("COLLAPSE game board")
        .accessibilityHint("Chạm để đổi giữa hai tương lai đang hiển thị trước khi lựa chọn bị khóa.")
    }

    private var background: some View {
        RadialGradient(
            colors: [skin.palette.backgroundTop, skin.palette.backgroundBottom],
            center: .center,
            startRadius: 24,
            endRadius: 620
        )
        .ignoresSafeArea()
    }

    private var ambientGlass: some View {
        ZStack {
            Circle()
                .fill(.thinMaterial)
                .frame(width: 330, height: 330)
                .opacity(0.32)
            Circle()
                .fill(.regularMaterial)
                .frame(width: 260, height: 260)
                .opacity(0.18)
            Circle()
                .stroke(skin.palette.primary.opacity(0.18), lineWidth: 1)
                .frame(width: 332, height: 332)
        }
        .allowsHitTesting(false)
    }
}