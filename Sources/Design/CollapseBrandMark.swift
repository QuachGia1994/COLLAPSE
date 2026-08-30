import SwiftUI

struct CollapseLogoSymbol: View {
    let tint: Color

    var body: some View {
        Canvas { context, size in
            let inset = min(size.width, size.height) * 0.08
            let bounds = CGRect(x: inset, y: inset, width: size.width - inset * 2, height: size.height - inset * 2)
            context.stroke(Path(ellipseIn: bounds), with: .color(tint.opacity(0.72)), lineWidth: 1.6)
            drawFutureLines(context: &context, bounds: bounds)
            drawNodes(context: &context, bounds: bounds)
        }
        .accessibilityHidden(true)
    }

    private func drawFutureLines(context: inout GraphicsContext, bounds: CGRect) {
        var upper = Path()
        upper.move(to: point(0.20, 0.62, in: bounds))
        upper.addQuadCurve(to: point(0.80, 0.38, in: bounds), control: point(0.50, 0.22, in: bounds))
        context.stroke(upper, with: .color(tint), style: StrokeStyle(lineWidth: 2.4, lineCap: .round))

        var lower = Path()
        lower.move(to: point(0.20, 0.42, in: bounds))
        lower.addQuadCurve(to: point(0.80, 0.66, in: bounds), control: point(0.50, 0.78, in: bounds))
        context.stroke(lower, with: .color(.purple.opacity(0.88)), style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
    }

    private func drawNodes(context: inout GraphicsContext, bounds: CGRect) {
        let start = point(0.18, 0.53, in: bounds)
        let end = point(0.82, 0.38, in: bounds)
        let hazard = point(0.75, 0.67, in: bounds)
        context.fill(Path(ellipseIn: circle(at: start, radius: 4.5)), with: .color(tint))
        context.fill(Path(ellipseIn: circle(at: end, radius: 4.5)), with: .color(.green))
        context.stroke(Path(ellipseIn: circle(at: hazard, radius: 6)), with: .color(.red), lineWidth: 2)
    }

    private func point(_ x: CGFloat, _ y: CGFloat, in bounds: CGRect) -> CGPoint {
        CGPoint(x: bounds.minX + bounds.width * x, y: bounds.minY + bounds.height * y)
    }

    private func circle(at center: CGPoint, radius: CGFloat) -> CGRect {
        CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
    }
}

struct CollapseBrandMark: View {
    let tint: Color
    var subtitle = "CHỌN TƯƠNG LAI"
    var compact = false

    var body: some View {
        HStack(spacing: compact ? 10 : 14) {
            CollapseLogoSymbol(tint: tint)
                .frame(width: compact ? 38 : 54, height: compact ? 38 : 54)
            VStack(alignment: .leading, spacing: compact ? 2 : 4) {
                Text("COLLAPSE")
                    .font(compact ? .headline.weight(.medium) : .system(size: 30, weight: .light, design: .rounded))
                    .tracking(compact ? 3 : 6)
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption2.weight(.medium))
                        .tracking(compact ? 1.5 : 2.5)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(subtitle.isEmpty ? "COLLAPSE" : "COLLAPSE, \(subtitle)")
    }
}