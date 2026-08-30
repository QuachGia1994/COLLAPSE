import SwiftUI

struct GameRenderSnapshot: Sendable {
    let round: RoundLayout
    let state: GameState
    let phase: GamePhase
    let selectedBranch: TimelineBranch
    let travelProgress: Double
    let rejectedBranch: TimelineBranch?
    let collapseProgress: Double
    let didCollectCurrentGem: Bool
    let feedback: GameFeedback?
    let choiceProgress: Double
    let feedbackProgress: Double?

    @MainActor
    init(engine: GameEngine, time: Double) {
        round = engine.round
        state = engine.state
        phase = engine.phase
        selectedBranch = engine.selectedBranch
        travelProgress = engine.travelProgress
        rejectedBranch = engine.rejectedBranch
        collapseProgress = engine.collapseProgress
        didCollectCurrentGem = engine.didCollectCurrentGem
        feedback = engine.feedback
        choiceProgress = engine.choiceProgress(at: time)
        feedbackProgress = engine.feedbackProgress(at: time)
    }
}

enum CollapseCanvasRenderer {
    static func draw(
        context: inout GraphicsContext,
        size: CGSize,
        snapshot: GameRenderSnapshot,
        skin: GameSkin,
        time: Double
    ) {
        drawPath(branch: .cyan, context: &context, size: size, snapshot: snapshot, skin: skin)
        drawPath(branch: .violet, context: &context, size: size, snapshot: snapshot, skin: skin)
        drawGhosts(context: &context, size: size, snapshot: snapshot, skin: skin, time: time)
        drawHazard(context: &context, size: size, snapshot: snapshot, skin: skin, time: time)
        drawGem(context: &context, size: size, snapshot: snapshot, skin: skin, time: time)
        drawPortal(context: &context, size: size, snapshot: snapshot, skin: skin)
        drawDecisionRing(context: &context, size: size, snapshot: snapshot, skin: skin)
        drawPlayer(context: &context, size: size, snapshot: snapshot, skin: skin, time: time)
        drawFeedback(context: &context, size: size, snapshot: snapshot, skin: skin)
    }

    private static func drawPath(
        branch: TimelineBranch,
        context: inout GraphicsContext,
        size: CGSize,
        snapshot: GameRenderSnapshot,
        skin: GameSkin
    ) {
        let future = snapshot.round.path(for: branch)
        let selected = snapshot.selectedBranch == branch
        let collapse = snapshot.rejectedBranch == branch ? snapshot.collapseProgress : 0
        let alpha = max(0, (selected ? 0.92 : 0.28) * (1 - collapse))
        let color = branchColor(branch, skin: skin)
        var path = Path()
        path.move(to: point(future.start, in: size))
        path.addQuadCurve(to: point(future.end, in: size), control: point(future.control, in: size))
        context.stroke(path, with: .color(color.opacity(alpha)), style: StrokeStyle(lineWidth: selected ? 3.2 : 1.8, lineCap: .round))
        drawPathDots(future: future, color: color, alpha: alpha, selected: selected, context: &context, size: size)
    }

    private static func drawPathDots(
        future: FuturePath,
        color: Color,
        alpha: Double,
        selected: Bool,
        context: inout GraphicsContext,
        size: CGSize
    ) {
        for index in 0...28 {
            let progress = Double(index) / 28
            let center = point(future.point(at: progress), in: size)
            let radius = selected && index.isMultiple(of: 2) ? 2.6 : 1.8
            fillCircle(center: center, radius: radius, color: color.opacity(alpha), context: &context)
        }
    }

    private static func drawGhosts(
        context: inout GraphicsContext,
        size: CGSize,
        snapshot: GameRenderSnapshot,
        skin: GameSkin,
        time: Double
    ) {
        for branch in TimelineBranch.allCases {
            let selected = snapshot.selectedBranch == branch
            let alpha = selected ? 0.72 : 0.22
            let color = branchColor(branch, skin: skin)
            let pulse = 1 + sin(time * skin.pulseFrequency * Double.pi * 2) * skin.pulseDepth
            for progress in [0.27, 0.50, 0.74] {
                let center = point(snapshot.round.path(for: branch).point(at: progress), in: size)
                fillGlow(center: center, radius: 5.5 * pulse, color: color.opacity(alpha), context: &context)
            }
        }
    }

    private static func drawHazard(
        context: inout GraphicsContext,
        size: CGSize,
        snapshot: GameRenderSnapshot,
        skin: GameSkin,
        time: Double
    ) {
        let hazard = snapshot.round.hazard
        let center = point(hazard.center, in: size)
        let baseRadius = min(size.width, size.height) * hazard.radius
        let radius = baseRadius * (1 + sin(time * 8) * 0.07)
        fillGlow(center: center, radius: radius * 1.45, color: skin.palette.danger.opacity(0.12), context: &context)
        strokeCircle(center: center, radius: radius, color: skin.palette.danger.opacity(0.95), lineWidth: 2.2, context: &context)
        drawSpikes(center: center, radius: radius * 0.72, color: skin.palette.danger, context: &context)
    }

    private static func drawSpikes(center: CGPoint, radius: Double, color: Color, context: inout GraphicsContext) {
        for index in 0..<8 {
            let angle = Double(index) / 8 * Double.pi * 2
            let inner = CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
            let outer = CGPoint(x: center.x + cos(angle) * radius * 1.34, y: center.y + sin(angle) * radius * 1.34)
            var spike = Path()
            spike.move(to: inner)
            spike.addLine(to: outer)
            context.stroke(spike, with: .color(color.opacity(0.88)), style: StrokeStyle(lineWidth: 2, lineCap: .round))
        }
    }

    private static func drawGem(
        context: inout GraphicsContext,
        size: CGSize,
        snapshot: GameRenderSnapshot,
        skin: GameSkin,
        time: Double
    ) {
        guard !snapshot.didCollectCurrentGem else { return }
        let center = point(snapshot.round.gem.center, in: size)
        let pulse = 1 + sin(time * 10) * 0.12
        let radius = min(size.width, size.height) * snapshot.round.gem.radius * pulse
        var diamond = Path()
        diamond.move(to: CGPoint(x: center.x, y: center.y - radius))
        diamond.addLine(to: CGPoint(x: center.x + radius * 0.78, y: center.y))
        diamond.addLine(to: CGPoint(x: center.x, y: center.y + radius))
        diamond.addLine(to: CGPoint(x: center.x - radius * 0.78, y: center.y))
        diamond.closeSubpath()
        context.fill(diamond, with: .color(skin.palette.safe.opacity(0.82)))
        context.stroke(diamond, with: .color(.white.opacity(0.82)), lineWidth: 1.2)
    }

    private static func drawPortal(
        context: inout GraphicsContext,
        size: CGSize,
        snapshot: GameRenderSnapshot,
        skin: GameSkin
    ) {
        let center = point(snapshot.round.cyanPath.end, in: size)
        fillGlow(center: center, radius: 14, color: skin.palette.safe.opacity(0.12), context: &context)
        strokeCircle(center: center, radius: 10, color: skin.palette.safe.opacity(0.90), lineWidth: 2.2, context: &context)
    }

    private static func drawDecisionRing(
        context: inout GraphicsContext,
        size: CGSize,
        snapshot: GameRenderSnapshot,
        skin: GameSkin
    ) {
        guard snapshot.state == .playing, snapshot.phase == .choosing else { return }
        let remaining = 1 - snapshot.choiceProgress
        let center = point(snapshot.round.cyanPath.start, in: size)
        var ring = Path()
        ring.addArc(center: center, radius: 19, startAngle: .degrees(-90), endAngle: .degrees(-90 + 360 * remaining), clockwise: false)
        let color = remaining < 0.28 ? skin.palette.danger : skin.palette.primary
        context.stroke(ring, with: .color(color.opacity(0.95)), style: StrokeStyle(lineWidth: 3, lineCap: .round))
    }

    private static func drawPlayer(
        context: inout GraphicsContext,
        size: CGSize,
        snapshot: GameRenderSnapshot,
        skin: GameSkin,
        time: Double
    ) {
        let center = playerPoint(size: size, snapshot: snapshot)
        let color = branchColor(snapshot.selectedBranch, skin: skin)
        let pulse = 1 + sin(time * skin.pulseFrequency * Double.pi * 2) * skin.pulseDepth
        fillGlow(center: center, radius: 13 * pulse, color: color.opacity(0.14), context: &context)
        fillCircle(center: center, radius: 7 * pulse, color: color, context: &context)
        strokeCircle(center: center, radius: 7 * pulse, color: .white.opacity(0.82), lineWidth: 1.6, context: &context)
    }

    private static func drawFeedback(
        context: inout GraphicsContext,
        size: CGSize,
        snapshot: GameRenderSnapshot,
        skin: GameSkin
    ) {
        guard let feedback = snapshot.feedback, let progress = snapshot.feedbackProgress else { return }
        let gamePoint = feedback.kind == .gem ? snapshot.round.gem.center : snapshot.round.hazard.center
        let center = point(gamePoint, in: size)
        let color = feedback.kind == .gem ? skin.palette.safe : skin.palette.danger
        let radius = 12 + progress * 42
        strokeCircle(center: center, radius: radius, color: color.opacity(1 - progress), lineWidth: 3 * (1 - progress) + 0.5, context: &context)
    }

    private static func playerPoint(size: CGSize, snapshot: GameRenderSnapshot) -> CGPoint {
        switch snapshot.phase {
        case .ready, .choosing:
            return point(snapshot.round.cyanPath.start, in: size)
        case .traveling, .dead:
            let future = snapshot.round.path(for: snapshot.selectedBranch)
            return point(future.point(at: snapshot.travelProgress), in: size)
        }
    }

    private static func branchColor(_ branch: TimelineBranch, skin: GameSkin) -> Color {
        branch == .cyan ? skin.palette.primary : skin.palette.secondary
    }

    private static func point(_ gamePoint: GamePoint, in size: CGSize) -> CGPoint {
        CGPoint(x: size.width * gamePoint.x, y: size.height * (1 - gamePoint.y))
    }

    private static func fillGlow(center: CGPoint, radius: Double, color: Color, context: inout GraphicsContext) {
        fillCircle(center: center, radius: radius * 1.55, color: color.opacity(0.36), context: &context)
        fillCircle(center: center, radius: radius, color: color, context: &context)
    }

    private static func fillCircle(center: CGPoint, radius: Double, color: Color, context: inout GraphicsContext) {
        let rect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
        context.fill(Path(ellipseIn: rect), with: .color(color))
    }

    private static func strokeCircle(
        center: CGPoint,
        radius: Double,
        color: Color,
        lineWidth: Double,
        context: inout GraphicsContext
    ) {
        let rect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
        context.stroke(Path(ellipseIn: rect), with: .color(color), lineWidth: lineWidth)
    }
}