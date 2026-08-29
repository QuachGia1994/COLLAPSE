import SwiftUI

@MainActor
struct GameBoardView: View {
    let session: GameSession
    let skin: GameSkin

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
            Canvas { context, size in
                drawBoard(context: &context, size: size, date: timeline.date)
            }
        }
        .background(background)
        .contentShape(Rectangle())
        .onTapGesture { session.toggleSelection() }
        .accessibilityLabel("COLLAPSE game board")
        .accessibilityHint("Tap to switch between the two visible futures before the timer commits your choice.")
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

    private func drawBoard(context: inout GraphicsContext, size: CGSize, date: Date) {
        let palette = skin.palette
        drawOrb(context: &context, size: size, palette: palette)
        drawHazard(context: &context, size: size, palette: palette, date: date)

        switch session.phase {
        case .ready, .choosing:
            drawPreview(context: &context, size: size, palette: palette, date: date)
        case .traveling:
            drawResolvedFuture(context: &context, size: size, palette: palette)
        case .dead:
            drawResolvedFuture(context: &context, size: size, palette: palette)
        }
    }

    private func drawOrb(context: inout GraphicsContext, size: CGSize, palette: SkinPalette) {
        let diameter = min(size.width * 0.92, size.height * 0.66)
        let rect = CGRect(x: (size.width - diameter) / 2, y: (size.height - diameter) / 2, width: diameter, height: diameter)
        context.stroke(Path(ellipseIn: rect), with: .color(palette.primary.opacity(0.28)), lineWidth: 1.5)
        context.stroke(Path(ellipseIn: rect.insetBy(dx: 5, dy: 5)), with: .color(palette.secondary.opacity(0.12)), lineWidth: 1)
    }

    private func drawPreview(context: inout GraphicsContext, size: CGSize, palette: SkinPalette, date: Date) {
        drawTimeline(context: &context, path: session.round.cyanPath, size: size, color: palette.primary, selected: session.selectedBranch == .cyan)
        drawTimeline(context: &context, path: session.round.violetPath, size: size, color: palette.secondary, selected: session.selectedBranch == .violet)
        drawGhosts(context: &context, path: session.round.cyanPath, size: size, color: palette.primary, date: date)
        drawGhosts(context: &context, path: session.round.violetPath, size: size, color: palette.secondary, date: date)
        drawPlayer(context: &context, point: session.round.cyanPath.start, size: size, color: color(for: session.selectedBranch, palette: palette))
        drawDecisionRing(context: &context, size: size, palette: palette)
    }

    private func drawResolvedFuture(context: inout GraphicsContext, size: CGSize, palette: SkinPalette) {
        let selectedPath = session.round.path(for: session.selectedBranch)
        drawTimeline(context: &context, path: selectedPath, size: size, color: color(for: session.selectedBranch, palette: palette), selected: true, solid: true)
        if let rejectedBranch = session.rejectedBranch {
            drawCollapse(context: &context, path: session.round.path(for: rejectedBranch), size: size, color: color(for: rejectedBranch, palette: palette))
        }
        let player = selectedPath.point(at: session.travelProgress)
        drawPlayer(context: &context, point: player, size: size, color: color(for: session.selectedBranch, palette: palette))
    }

    private func drawTimeline(context: inout GraphicsContext, path: FuturePath, size: CGSize, color: Color, selected: Bool, solid: Bool = false) {
        var shape = Path()
        shape.move(to: path.start.cgPoint(in: size))
        shape.addQuadCurve(to: path.end.cgPoint(in: size), control: path.control.cgPoint(in: size))
        let alpha = selected ? 0.95 : 0.34
        let style = StrokeStyle(lineWidth: selected ? 3 : 1.5, lineCap: .round, dash: solid ? [] : [9, 8])
        context.stroke(shape, with: .color(color.opacity(alpha * 0.22)), style: StrokeStyle(lineWidth: selected ? 10 : 5, lineCap: .round, dash: solid ? [] : [9, 8]))
        context.stroke(shape, with: .color(color.opacity(alpha)), style: style)
    }

    private func drawGhosts(context: inout GraphicsContext, path: FuturePath, size: CGSize, color: Color, date: Date) {
        let pulse = (sin(date.timeIntervalSinceReferenceDate * 5) + 1) / 2
        for (index, t) in [0.27, 0.50, 0.74].enumerated() {
            let point = path.point(at: t).cgPoint(in: size)
            let radius = 4.0 + Double(index) * 0.7 + pulse * 0.8
            context.fill(Path(ellipseIn: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)), with: .color(color.opacity(0.30 + Double(index) * 0.12)))
        }
    }

    private func drawHazard(context: inout GraphicsContext, size: CGSize, palette: SkinPalette, date: Date) {
        let point = session.round.hazard.center.cgPoint(in: size)
        let radius = min(size.width, size.height) * session.round.hazard.radius
        let pulse = 1 + sin(date.timeIntervalSinceReferenceDate * 7) * 0.08
        let outer = radius * pulse
        context.fill(Path(ellipseIn: CGRect(x: point.x - outer * 2, y: point.y - outer * 2, width: outer * 4, height: outer * 4)), with: .color(palette.danger.opacity(0.08)))
        context.stroke(Path(ellipseIn: CGRect(x: point.x - outer, y: point.y - outer, width: outer * 2, height: outer * 2)), with: .color(palette.danger.opacity(0.95)), lineWidth: 2)
        context.stroke(Path(ellipseIn: CGRect(x: point.x - outer * 0.52, y: point.y - outer * 0.52, width: outer * 1.04, height: outer * 1.04)), with: .color(.white.opacity(0.24)), lineWidth: 1)
    }

    private func drawDecisionRing(context: inout GraphicsContext, size: CGSize, palette: SkinPalette) {
        guard session.phase == .choosing else { return }
        let point = session.round.cyanPath.start.cgPoint(in: size)
        let remaining = 1 - session.choiceProgress
        let radius = 18.0
        var ring = Path()
        ring.addArc(center: point, radius: radius, startAngle: .degrees(-90), endAngle: .degrees(-90 + 360 * remaining), clockwise: false)
        context.stroke(ring, with: .color((remaining < 0.28 ? palette.danger : palette.primary).opacity(0.95)), style: StrokeStyle(lineWidth: 3, lineCap: .round))
    }

    private func drawPlayer(context: inout GraphicsContext, point: GamePoint, size: CGSize, color: Color) {
        let center = point.cgPoint(in: size)
        context.fill(Path(ellipseIn: CGRect(x: center.x - 14, y: center.y - 14, width: 28, height: 28)), with: .color(color.opacity(0.12)))
        context.fill(Path(ellipseIn: CGRect(x: center.x - 7, y: center.y - 7, width: 14, height: 14)), with: .color(color))
        context.fill(Path(ellipseIn: CGRect(x: center.x - 3, y: center.y - 3, width: 6, height: 6)), with: .color(.white.opacity(0.90)))
    }

    private func drawCollapse(context: inout GraphicsContext, path: FuturePath, size: CGSize, color: Color) {
        let progress = session.collapseProgress
        guard progress < 1 else { return }
        for index in 0..<14 {
            let t = Double(index) / 13
            let base = path.point(at: t).cgPoint(in: size)
            let direction = index.isMultiple(of: 2) ? -1.0 : 1.0
            let offset = CGFloat(progress * Double(10 + index) * direction)
            let shard = CGRect(x: base.x + offset - 2, y: base.y + CGFloat(progress * Double(index % 4) * 4) - 1, width: 4 + CGFloat(index % 3), height: 2)
            context.fill(Path(roundedRect: shard, cornerRadius: 1), with: .color(color.opacity((1 - progress) * 0.72)))
        }
    }

    private func color(for branch: TimelineBranch, palette: SkinPalette) -> Color {
        branch == .cyan ? palette.primary : palette.secondary
    }
}
