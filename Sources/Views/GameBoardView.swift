import SpriteKit
import SwiftUI

@MainActor
struct GameBoardView: View {
    let engine: GameEngine
    let skin: GameSkin
    @State private var scene: CollapseScene

    init(engine: GameEngine, skin: GameSkin) {
        self.engine = engine
        self.skin = skin
        scene = CollapseScene(engine: engine, skin: skin)
    }

    var body: some View {
        SpriteView(
            scene: scene,
            transition: nil,
            isPaused: engine.state == .paused,
            preferredFramesPerSecond: 120
        )
        .background(background)
        .onChange(of: skin) { _, newSkin in
            scene.apply(skin: newSkin)
        }
        .accessibilityLabel("COLLAPSE game board")
        .accessibilityHint("Chạm để đổi giữa hai tương lai đang hiển thị trước khi lựa chọn bị khóa.")
    }

    private var background: some View {
        RadialGradient(
            colors: [skin.palette.backgroundTop, skin.palette.backgroundBottom],
            center: .center,
            startRadius: 20,
            endRadius: 620
        )
        .ignoresSafeArea()
    }
}
