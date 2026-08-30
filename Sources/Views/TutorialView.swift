import SwiftUI

@MainActor
struct TutorialView: View {
    @Environment(PlayerProfile.self) private var profile
    @Environment(\.dismiss) private var dismiss
    @State private var step = 0
    @State private var selectedBranch: TimelineBranch = .cyan

    let isReplay: Bool

    private let items = [
        TutorialItem(title: "Nhìn 2 tương lai", detail: "Hai đường cho biết trước kết quả. Tìm nhánh tránh vùng đỏ.", symbol: "eye"),
        TutorialItem(title: "Chạm để đổi nhánh", detail: "Chạm vào vùng chơi để đổi lựa chọn. Không cần vuốt hay giữ.", symbol: "hand.tap"),
        TutorialItem(title: "Chốt lựa chọn", detail: "Hết thời gian, nhánh đã chọn thành hiện thực và nhánh còn lại vỡ.", symbol: "checkmark.circle")
    ]

    init(isReplay: Bool = false) {
        self.isReplay = isReplay
    }

    var body: some View {
        GeometryReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 18) {
                    header
                    tutorialBoard
                    explanationCard
                    progress
                    primaryAction
                }
                .frame(maxWidth: 430)
                .frame(minHeight: proxy.size.height, alignment: .center)
                .padding(.horizontal, 20)
                .padding(.vertical, 18)
                .frame(maxWidth: .infinity)
            }
            .background(background)
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            CollapseBrandMark(tint: .cyan, subtitle: "CÁCH CHƠI", compact: true)
            Spacer()
            Button(isReplay ? "Đóng" : "Bỏ qua") { finishTutorial() }
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
                .accessibilityIdentifier("tutorial.close")
        }
    }

    private var tutorialBoard: some View {
        TutorialBoard(step: step, selectedBranch: selectedBranch)
            .aspectRatio(1.08, contentMode: .fit)
            .frame(maxWidth: 390)
            .contentShape(Rectangle())
            .onTapGesture {
                guard step == 1 else { return }
                withAnimation(.snappy(duration: 0.22)) {
                    selectedBranch = selectedBranch.other
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(items[step].detail)
            .accessibilityIdentifier("tutorial.board")
    }

    private var explanationCard: some View {
        VStack(spacing: 9) {
            Image(systemName: items[step].symbol)
                .font(.title2)
                .foregroundStyle(.cyan)
            Text("BƯỚC \(step + 1)")
                .font(.caption.weight(.semibold))
                .tracking(2)
                .foregroundStyle(.cyan)
            Text(items[step].title)
                .font(.title2.weight(.semibold))
                .multilineTextAlignment(.center)
            Text(items[step].detail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 330)
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var progress: some View {
        HStack(spacing: 7) {
            ForEach(items.indices, id: \.self) { index in
                Capsule()
                    .fill(index == step ? Color.cyan : Color.white.opacity(0.18))
                    .frame(width: index == step ? 26 : 7, height: 7)
            }
        }
        .accessibilityHidden(true)
    }

    private var primaryAction: some View {
        Button(primaryActionTitle) { advance() }
            .buttonStyle(.borderedProminent)
            .tint(.cyan)
            .controlSize(.large)
            .frame(maxWidth: .infinity)
            .accessibilityIdentifier("tutorial.next")
    }

    private var primaryActionTitle: String {
        guard step == items.count - 1 else { return "TIẾP" }
        return isReplay ? "XONG" : "BẮT ĐẦU"
    }

    private var background: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.03, green: 0.05, blue: 0.12), .black], startPoint: .top, endPoint: .bottom)
            Circle()
                .fill(.thinMaterial)
                .frame(width: 320, height: 320)
                .offset(x: -150, y: -300)
                .opacity(0.22)
        }
        .ignoresSafeArea()
    }

    private func advance() {
        guard step < items.count - 1 else {
            finishTutorial()
            return
        }
        withAnimation(.snappy(duration: 0.24)) {
            step += 1
        }
    }

    private func finishTutorial() {
        if isReplay {
            dismiss()
            return
        }
        profile.didCompleteTutorial = true
    }
}

private struct TutorialItem {
    let title: String
    let detail: String
    let symbol: String
}

private struct TutorialBoard: View {
    let step: Int
    let selectedBranch: TimelineBranch

    var body: some View {
        Canvas { context, size in
            let geometry = TutorialGeometry(size: size)
            drawGlass(context: &context, geometry: geometry)
            drawHazard(context: &context, geometry: geometry)
            drawTimelines(context: &context, geometry: geometry)
            drawNodes(context: &context, geometry: geometry)
        }
        .overlay {
            if step == 1 {
                Image(systemName: "hand.tap.fill")
                    .font(.system(size: 42, weight: .light))
                    .foregroundStyle(.white.opacity(0.88))
                    .padding(18)
                    .background(.thinMaterial, in: Circle())
            }
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        }
    }

    private func drawGlass(context: inout GraphicsContext, geometry: TutorialGeometry) {
        context.fill(Path(ellipseIn: geometry.orbit), with: .color(.white.opacity(0.025)))
        context.stroke(Path(ellipseIn: geometry.orbit), with: .color(.cyan.opacity(0.20)), lineWidth: 1.5)
    }

    private func drawHazard(context: inout GraphicsContext, geometry: TutorialGeometry) {
        context.fill(Path(ellipseIn: geometry.hazardGlow), with: .color(.red.opacity(0.10)))
        context.stroke(Path(ellipseIn: geometry.hazardRing), with: .color(.red), lineWidth: 2.2)
    }

    private func drawTimelines(context: inout GraphicsContext, geometry: TutorialGeometry) {
        let cyanSelected = selectedBranch == .cyan
        guard step != 2 else {
            drawCommittedTimeline(context: &context, geometry: geometry, cyanSelected: cyanSelected)
            return
        }
        context.stroke(geometry.cyanPath, with: .color(.cyan.opacity(cyanSelected ? 0.96 : 0.30)), style: lineStyle(selected: cyanSelected))
        context.stroke(geometry.violetPath, with: .color(.purple.opacity(cyanSelected ? 0.30 : 0.96)), style: lineStyle(selected: !cyanSelected))
    }

    private func drawCommittedTimeline(context: inout GraphicsContext, geometry: TutorialGeometry, cyanSelected: Bool) {
        let selectedPath = cyanSelected ? geometry.cyanPath : geometry.violetPath
        let selectedColor: Color = cyanSelected ? .cyan : .purple
        context.stroke(selectedPath, with: .color(selectedColor), style: StrokeStyle(lineWidth: 3, lineCap: .round))
        drawShards(context: &context, geometry: geometry, cyanRejected: !cyanSelected)
    }

    private func drawNodes(context: inout GraphicsContext, geometry: TutorialGeometry) {
        context.fill(Path(ellipseIn: geometry.startNode), with: .color(selectedBranch == .cyan ? .cyan : .purple))
        context.fill(Path(ellipseIn: geometry.endNode), with: .color(.green))
    }

    private func drawShards(context: inout GraphicsContext, geometry: TutorialGeometry, cyanRejected: Bool) {
        let color: Color = cyanRejected ? .cyan : .purple
        for index in 0..<12 {
            let progress = CGFloat(index + 2) / 15
            let center = geometry.shardPoint(progress: progress, upper: cyanRejected)
            let rect = CGRect(x: center.x - 3, y: center.y - 1, width: 6, height: 2)
            context.fill(Path(roundedRect: rect, cornerRadius: 1), with: .color(color.opacity(0.68)))
        }
    }

    private func lineStyle(selected: Bool) -> StrokeStyle {
        StrokeStyle(lineWidth: selected ? 3 : 1.5, lineCap: .round, dash: [9, 8])
    }
}

private struct TutorialGeometry {
    let size: CGSize

    var start: CGPoint { CGPoint(x: size.width * 0.14, y: size.height * 0.52) }
    var end: CGPoint { CGPoint(x: size.width * 0.86, y: size.height * 0.52) }
    var upper: CGPoint { CGPoint(x: size.width * 0.50, y: size.height * 0.20) }
    var lower: CGPoint { CGPoint(x: size.width * 0.50, y: size.height * 0.80) }
    var hazardCenter: CGPoint { CGPoint(x: size.width * 0.61, y: size.height * 0.68) }

    var cyanPath: Path { timeline(control: upper) }
    var violetPath: Path { timeline(control: lower) }

    var orbit: CGRect {
        let diameter = min(size.width * 0.92, size.height * 0.92)
        return CGRect(x: (size.width - diameter) / 2, y: (size.height - diameter) / 2, width: diameter, height: diameter)
    }

    var hazardGlow: CGRect { circle(center: hazardCenter, radius: min(size.width, size.height) * 0.075) }
    var hazardRing: CGRect { circle(center: hazardCenter, radius: min(size.width, size.height) * 0.038) }
    var startNode: CGRect { circle(center: start, radius: 8) }
    var endNode: CGRect { circle(center: end, radius: 9) }

    func shardPoint(progress: CGFloat, upper: Bool) -> CGPoint {
        quadraticPoint(start: start, control: upper ? self.upper : lower, end: end, progress: progress)
    }

    private func timeline(control: CGPoint) -> Path {
        var path = Path()
        path.move(to: start)
        path.addQuadCurve(to: end, control: control)
        return path
    }

    private func quadraticPoint(start: CGPoint, control: CGPoint, end: CGPoint, progress: CGFloat) -> CGPoint {
        let inverse = 1 - progress
        return CGPoint(
            x: inverse * inverse * start.x + 2 * inverse * progress * control.x + progress * progress * end.x,
            y: inverse * inverse * start.y + 2 * inverse * progress * control.y + progress * progress * end.y
        )
    }

    private func circle(center: CGPoint, radius: CGFloat) -> CGRect {
        CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
    }
}