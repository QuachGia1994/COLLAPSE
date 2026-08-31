import SwiftUI

/// Colors sampled from the canonical AppIcon artwork. Every in-app logo
/// surface draws this exact composition so the brand matches the app-screen
/// icon everywhere.
private enum CollapseIconPalette {
    static let ringCyan = Color(red: 0x70 / 255, green: 0xEE / 255, blue: 0xFF / 255)
    static let ringMagenta = Color(red: 0xF7 / 255, green: 0x73 / 255, blue: 0xFF / 255)
    static let dashCyan = Color(red: 0x28 / 255, green: 0xDA / 255, blue: 0xFF / 255)
    static let dashMagenta = Color(red: 0xD4 / 255, green: 0x50 / 255, blue: 0xFF / 255)
    static let planetLight = Color(red: 0x9A / 255, green: 0xB2 / 255, blue: 0xCE / 255)
    static let planetMid = Color(red: 0x86 / 255, green: 0xA0 / 255, blue: 0xE7 / 255)
    static let planetDeep = Color(red: 0x3A / 255, green: 0x46 / 255, blue: 0x8E / 255)
    static let planetGlow = Color(red: 0x96 / 255, green: 0x3C / 255, blue: 0xBD / 255)
    static let shard = Color(red: 0x96 / 255, green: 0x5F / 255, blue: 0xFF / 255)
}

/// Canonical COLLAPSE logo symbol mirroring the AppIcon artwork:
/// gradient orbit ring (cyan -> magenta), central planet sphere, two dashed
/// timelines, cyan/magenta nodes, and purple shard triangles. All geometry
/// is proportional to the drawn bounds so every size renders identically.
struct CollapseLogoSymbol: View {
    // Kept for call-site compatibility; the artwork always uses the
    // canonical icon palette.
    let tint: Color

    var body: some View {
        Canvas { context, size in
            let minDimension = min(size.width, size.height)
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let ringRadius = minDimension * 0.375
            let planetRadius = ringRadius * 0.61

            drawPlanetGlow(context: &context, center: center, minDimension: minDimension, ringRadius: ringRadius)
            drawPlanet(context: &context, center: center, minDimension: minDimension, planetRadius: planetRadius)
            drawOrbitRing(context: &context, center: center, ringRadius: ringRadius, minDimension: minDimension)
            drawTimelines(context: &context, center: center, ringRadius: ringRadius, minDimension: minDimension)
            drawNodes(context: &context, center: center, ringRadius: ringRadius, minDimension: minDimension)
            drawShards(context: &context, minDimension: minDimension)
        }
        .accessibilityHidden(true)
    }

    private func drawPlanetGlow(context: inout GraphicsContext, center: CGPoint, minDimension: CGFloat, ringRadius: CGFloat) {
        let glowCenter = CGPoint(x: center.x, y: center.y - minDimension * 0.05)
        let shading = GraphicsContext.Shading.radialGradient(
            Gradient(colors: [CollapseIconPalette.planetGlow.opacity(0.55), CollapseIconPalette.planetGlow.opacity(0)]),
            center: glowCenter,
            startRadius: 0,
            endRadius: ringRadius * 1.05
        )
        context.fill(Path(ellipseIn: circle(at: glowCenter, radius: ringRadius * 1.05)), with: shading)
    }

    private func drawPlanet(context: inout GraphicsContext, center: CGPoint, minDimension: CGFloat, planetRadius: CGFloat) {
        let lightCenter = CGPoint(x: center.x - planetRadius * 0.35, y: center.y - planetRadius * 0.45)
        let shading = GraphicsContext.Shading.radialGradient(
            Gradient(colors: [CollapseIconPalette.planetLight, CollapseIconPalette.planetMid, CollapseIconPalette.planetDeep]),
            center: lightCenter,
            startRadius: 0,
            endRadius: planetRadius * 1.55
        )
        context.fill(Path(ellipseIn: circle(at: center, radius: planetRadius)), with: shading)
    }

    private func drawOrbitRing(context: inout GraphicsContext, center: CGPoint, ringRadius: CGFloat, minDimension: CGFloat) {
        let ring = Path(ellipseIn: circle(at: center, radius: ringRadius))
        let shading = GraphicsContext.Shading.angularGradient(
            Gradient(colors: [CollapseIconPalette.ringMagenta, CollapseIconPalette.ringCyan, CollapseIconPalette.ringMagenta]),
            center: center,
            startAngle: .degrees(0),
            endAngle: .degrees(360)
        )
        context.stroke(ring, with: shading, style: StrokeStyle(lineWidth: max(1, minDimension * 0.012), lineCap: .round))
    }

    private func drawTimelines(context: inout GraphicsContext, center: CGPoint, ringRadius: CGFloat, minDimension: CGFloat) {
        let start = CGPoint(x: center.x - ringRadius, y: center.y + minDimension * 0.027)
        let end = CGPoint(x: center.x + ringRadius, y: center.y - minDimension * 0.024)

        var upper = Path()
        upper.move(to: start)
        upper.addQuadCurve(to: end, control: CGPoint(x: center.x, y: center.y - minDimension * 0.18))
        context.stroke(
            upper,
            with: .color(CollapseIconPalette.dashCyan),
            style: StrokeStyle(lineWidth: minDimension * 0.014, lineCap: .round, dash: [minDimension * 0.021, minDimension * 0.013])
        )

        var lower = Path()
        lower.move(to: start)
        lower.addQuadCurve(to: end, control: CGPoint(x: center.x, y: center.y + minDimension * 0.18))
        context.stroke(
            lower,
            with: .color(CollapseIconPalette.dashMagenta),
            style: StrokeStyle(lineWidth: minDimension * 0.014, lineCap: .round, dash: [minDimension * 0.021, minDimension * 0.013])
        )
    }

    private func drawNodes(context: inout GraphicsContext, center: CGPoint, ringRadius: CGFloat, minDimension: CGFloat) {
        let nodeRadius = minDimension * 0.023
        let start = CGPoint(x: center.x - ringRadius, y: center.y + minDimension * 0.027)
        let end = CGPoint(x: center.x + ringRadius, y: center.y - minDimension * 0.024)
        context.fill(Path(ellipseIn: circle(at: start, radius: nodeRadius)), with: .color(CollapseIconPalette.ringCyan))
        context.fill(Path(ellipseIn: circle(at: end, radius: nodeRadius)), with: .color(CollapseIconPalette.ringMagenta))
    }

    private func drawShards(context: inout GraphicsContext, minDimension: CGFloat) {
        let width = minDimension * 0.021
        let height = minDimension * 0.019
        let spacingX = minDimension * 0.044
        let rowOffsets: [(y: CGFloat, x: CGFloat)] = [
            (0.195, 0.700),
            (0.275, 0.712),
            (0.355, 0.690)
        ]
        for row in rowOffsets {
            for column in 0..<5 {
                let origin = CGPoint(x: minDimension * row.x + CGFloat(column) * spacingX, y: minDimension * row.y)
                var triangle = Path()
                triangle.move(to: origin)
                triangle.addLine(to: CGPoint(x: origin.x + width, y: origin.y + height / 2))
                triangle.addLine(to: CGPoint(x: origin.x, y: origin.y + height))
                triangle.closeSubpath()
                context.stroke(triangle, with: .color(CollapseIconPalette.shard), lineWidth: max(0.8, minDimension * 0.003))
            }
        }
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
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption2.weight(.medium))
                        .tracking(compact ? 1.5 : 2.5)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(subtitle.isEmpty ? "COLLAPSE" : "COLLAPSE, \(subtitle)")
    }
}
