import SpriteKit
import SwiftUI

@MainActor
final class CollapseScene: SKScene {
    private let engine: GameEngine
    private let budgetMonitor = RenderBudgetMonitor()
    private var skin: GameSkin
    private var cyanDots: [SKShapeNode] = []
    private var violetDots: [SKShapeNode] = []
    private var cyanGhosts: [SKShapeNode] = []
    private var violetGhosts: [SKShapeNode] = []
    private let playerNode = SKShapeNode(circleOfRadius: 7)
    private let hazardNode = SKShapeNode(circleOfRadius: 10)
    private let portalNode = SKShapeNode(circleOfRadius: 9)
    private let decisionRing = SKShapeNode()
    private var lastRound: RoundLayout?
    private var lastSelection: TimelineBranch?
    private var lastPhase: GamePhase?

    init(engine: GameEngine, skin: GameSkin) {
        self.engine = engine
        self.skin = skin
        super.init(size: CGSize(width: 390, height: 844))
        scaleMode = .resizeFill
        anchorPoint = .zero
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        view.preferredFramesPerSecond = 120
        view.ignoresSiblingOrder = true
        rebuildScene()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        guard size.width > 1, size.height > 1 else { return }
        rebuildScene()
    }

    override func update(_ currentTime: TimeInterval) {
        budgetMonitor.record(timestamp: currentTime)
        engine.tick()

        if lastRound != engine.round {
            rebuildRound()
        }
        if lastSelection != engine.selectedBranch {
            updatePathStyles()
        }
        if lastPhase != engine.phase {
            handlePhaseChange()
        }
        updateDynamicNodes()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        engine.toggleSelection()
    }

    func apply(skin: GameSkin) {
        guard self.skin != skin else { return }
        self.skin = skin
        rebuildScene()
    }

    private func rebuildScene() {
        removeAllChildren()
        backgroundColor = UIColor(skin.palette.backgroundBottom)
        addAmbientGlass()
        addChild(hazardNode)
        addChild(portalNode)
        addChild(decisionRing)
        addChild(playerNode)
        rebuildRound()
        configurePlayer()
    }

    private func addAmbientGlass() {
        let radius = min(size.width * 0.46, size.height * 0.32)
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let glow = SKShapeNode(circleOfRadius: radius * 1.05)
        glow.position = center
        glow.fillColor = UIColor(skin.palette.primary).withAlphaComponent(0.025)
        glow.strokeColor = UIColor(skin.palette.primary).withAlphaComponent(0.22)
        glow.lineWidth = 1.5
        glow.glowWidth = 4
        glow.zPosition = -5
        addChild(glow)

        let inner = SKShapeNode(circleOfRadius: radius)
        inner.position = center
        inner.fillColor = .clear
        inner.strokeColor = UIColor(skin.palette.secondary).withAlphaComponent(0.12)
        inner.lineWidth = 1
        inner.zPosition = -4
        addChild(inner)
    }

    private func rebuildRound() {
        cyanDots.forEach { $0.removeFromParent() }
        violetDots.forEach { $0.removeFromParent() }
        cyanGhosts.forEach { $0.removeFromParent() }
        violetGhosts.forEach { $0.removeFromParent() }
        cyanDots = makeTimelineDots(for: .cyan)
        violetDots = makeTimelineDots(for: .violet)
        cyanGhosts = makeGhosts(for: .cyan)
        violetGhosts = makeGhosts(for: .violet)
        (cyanDots + violetDots + cyanGhosts + violetGhosts).forEach(addChild)
        configureHazard()
        configurePortal()
        configurePlayer()
        updatePathStyles()
        lastRound = engine.round
        lastPhase = engine.phase
    }

    private func makeTimelineDots(for branch: TimelineBranch) -> [SKShapeNode] {
        let path = engine.round.path(for: branch)
        return (0...34).map { index in
            let node = SKShapeNode(circleOfRadius: 2)
            node.position = scenePoint(path.point(at: Double(index) / 34))
            node.fillColor = branchColor(branch)
            node.strokeColor = .clear
            node.zPosition = 2
            return node
        }
    }

    private func makeGhosts(for branch: TimelineBranch) -> [SKShapeNode] {
        let path = engine.round.path(for: branch)
        return [0.27, 0.50, 0.74].enumerated().map { index, progress in
            let node = SKShapeNode(circleOfRadius: 4 + CGFloat(index) * 0.7)
            node.position = scenePoint(path.point(at: progress))
            node.fillColor = branchColor(branch).withAlphaComponent(0.42)
            node.strokeColor = .clear
            node.glowWidth = 5
            node.zPosition = 3
            let pulse = SKAction.sequence([
                .scale(to: 1.18, duration: 0.42),
                .scale(to: 0.92, duration: 0.42)
            ])
            node.run(.repeatForever(pulse))
            return node
        }
    }

    private func configureHazard() {
        let radius = min(size.width, size.height) * CGFloat(engine.round.hazard.radius)
        hazardNode.path = CGPath(ellipseIn: CGRect(x: -radius, y: -radius, width: radius * 2, height: radius * 2), transform: nil)
        hazardNode.position = scenePoint(engine.round.hazard.center)
        hazardNode.fillColor = UIColor(skin.palette.danger).withAlphaComponent(0.12)
        hazardNode.strokeColor = UIColor(skin.palette.danger)
        hazardNode.lineWidth = 2
        hazardNode.glowWidth = 13
        hazardNode.zPosition = 4
        hazardNode.removeAllActions()
        hazardNode.run(.repeatForever(.sequence([
            .scale(to: 1.10, duration: 0.32),
            .scale(to: 0.94, duration: 0.32)
        ])))
    }

    private func configurePortal() {
        portalNode.position = scenePoint(engine.round.cyanPath.end)
        portalNode.fillColor = UIColor(skin.palette.safe).withAlphaComponent(0.18)
        portalNode.strokeColor = UIColor(skin.palette.safe)
        portalNode.lineWidth = 2
        portalNode.glowWidth = 10
        portalNode.zPosition = 4
    }

    private func configurePlayer() {
        playerNode.fillColor = branchColor(engine.selectedBranch)
        playerNode.strokeColor = .white.withAlphaComponent(0.82)
        playerNode.lineWidth = 2
        playerNode.glowWidth = 12
        playerNode.zPosition = 8
    }

    private func updatePathStyles() {
        style(dots: cyanDots, branch: .cyan)
        style(dots: violetDots, branch: .violet)
        style(ghosts: cyanGhosts, branch: .cyan)
        style(ghosts: violetGhosts, branch: .violet)
        playerNode.fillColor = branchColor(engine.selectedBranch)
        lastSelection = engine.selectedBranch
    }

    private func style(dots: [SKShapeNode], branch: TimelineBranch) {
        let selected = engine.selectedBranch == branch
        for (index, node) in dots.enumerated() {
            node.alpha = selected ? 0.92 : 0.28
            node.setScale(selected && index.isMultiple(of: 2) ? 1.20 : 1)
            node.glowWidth = selected ? 4 : 0
        }
    }

    private func style(ghosts: [SKShapeNode], branch: TimelineBranch) {
        let selected = engine.selectedBranch == branch
        ghosts.forEach { $0.alpha = selected ? 0.95 : 0.34 }
    }

    private func handlePhaseChange() {
        if engine.phase == .traveling, let rejectedBranch = engine.rejectedBranch {
            spawnCollapseShards(for: rejectedBranch)
        }
        lastPhase = engine.phase
    }

    private func updateDynamicNodes() {
        switch engine.phase {
        case .ready:
            playerNode.position = scenePoint(engine.round.cyanPath.start)
            decisionRing.isHidden = true
        case .choosing:
            playerNode.position = scenePoint(engine.round.cyanPath.start)
            decisionRing.isHidden = false
            updateDecisionRing()
        case .traveling, .dead:
            let path = engine.round.path(for: engine.selectedBranch)
            playerNode.position = scenePoint(path.point(at: engine.travelProgress))
            decisionRing.isHidden = true
        }
    }

    private func updateDecisionRing() {
        let remaining = 1 - engine.choiceProgress
        let remainingAngle = CGFloat(remaining)
        let center = scenePoint(engine.round.cyanPath.start)
        let radius: CGFloat = 18
        let ring = CGMutablePath()
        ring.addArc(
            center: center,
            radius: radius,
            startAngle: -.pi / 2,
            endAngle: -.pi / 2 + .pi * 2 * remainingAngle,
            clockwise: false
        )
        decisionRing.path = ring
        decisionRing.strokeColor = remaining < 0.28 ? UIColor(skin.palette.danger) : UIColor(skin.palette.primary)
        decisionRing.lineWidth = 3
        decisionRing.glowWidth = 4
        decisionRing.zPosition = 7
    }

    private func spawnCollapseShards(for branch: TimelineBranch) {
        let path = engine.round.path(for: branch)
        for index in 0..<18 {
            let progress = Double(index) / 17
            let shard = SKShapeNode(rectOf: CGSize(width: CGFloat(5 + index % 3), height: 2), cornerRadius: 1)
            shard.position = scenePoint(path.point(at: progress))
            shard.fillColor = branchColor(branch)
            shard.strokeColor = .clear
            shard.zPosition = 6
            addChild(shard)
            let direction: CGFloat = index.isMultiple(of: 2) ? -1 : 1
            let move = SKAction.moveBy(x: direction * CGFloat(10 + index), y: CGFloat((index % 5) * 5 - 10), duration: 0.42)
            let fade = SKAction.fadeOut(withDuration: 0.42)
            shard.run(.sequence([.group([move, fade]), .removeFromParent()]))
        }
    }

    private func scenePoint(_ point: GamePoint) -> CGPoint {
        CGPoint(x: size.width * CGFloat(point.x), y: size.height * CGFloat(1 - point.y))
    }

    private func branchColor(_ branch: TimelineBranch) -> UIColor {
        UIColor(branch == .cyan ? skin.palette.primary : skin.palette.secondary)
    }
}
