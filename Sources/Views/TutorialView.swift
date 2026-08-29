import SwiftUI

@MainActor
struct TutorialView: View {
    @Environment(PlayerProfile.self) private var profile
    @State private var step = 0
    @State private var selectedBranch: TimelineBranch = .cyan

    private let items = [
        TutorialItem(title: "Nhìn 2 tương lai", detail: "Hai đường cho biết trước kết quả. Tìm nhánh tránh vùng đỏ.", symbol: "eye"),
        TutorialItem(title: "Chạm để đổi nhánh", detail: "Mỗi lần chạm đổi lựa chọn. Không cần vuốt hay giữ.", symbol: "hand.tap"),
        TutorialItem(title: "Chốt lựa chọn", detail: "Hết thời gian, nhánh đã chọn thành hiện thực. Nhánh còn lại vỡ.", symbol: "checkmark.circle")
    ]

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.03, green: 0.05, blue: 0.12), .black], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 22) {
                Text("CÁCH CHƠI")
                    .font(.headline.weight(.medium))
                    .tracking(5)
                    .foregroundStyle(.white.opacity(0.82))

                TutorialBoard(step: step, selectedBranch: selectedBranch)
                    .frame(maxHeight: 430)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        guard step == 1 else { return }
                        selectedBranch = selectedBranch.other
                    }

                VStack(spacing: 8) {
                    Image(systemName: items[step].symbol)
                        .font(.title2)
                        .foregroundStyle(.cyan)
                    Text("BƯỚC \(step + 1)")
                        .font(.caption.weight(.semibold))
                        .tracking(2)
                        .foregroundStyle(.cyan)
                    Text(items[step].title)
                        .font(.title2.weight(.semibold))
                    Text(items[step].detail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 320)
                }

                HStack(spacing: 7) {
                    ForEach(items.indices, id: \.self) { index in
                        Capsule()
                            .fill(index == step ? Color.cyan : Color.white.opacity(0.16))
                            .frame(width: index == step ? 24 : 7, height: 7)
                    }
                }

                Button(step == items.count - 1 ? "BẮT ĐẦU" : "TIẾP") {
                    if step == items.count - 1 {
                        profile.didCompleteTutorial = true
                    } else {
                        withAnimation(.snappy) { step += 1 }
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.cyan)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
            }
            .padding(24)
        }
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
        GeometryReader { proxy in
            Canvas { context, size in
                let start = CGPoint(x: size.width * 0.13, y: size.height * 0.52)
                let end = CGPoint(x: size.width * 0.86, y: size.height * 0.52)
                let upper = CGPoint(x: size.width * 0.50, y: size.height * 0.20)
                let lower = CGPoint(x: size.width * 0.50, y: size.height * 0.80)
                let cyan = path(start: start, control: upper, end: end)
                let violet = path(start: start, control: lower, end: end)
                let chosenCyan = selectedBranch == .cyan
                let collapse = step == 2

                drawOrbit(context: &context, size: size)
                drawHazard(context: &context, center: CGPoint(x: size.width * 0.61, y: size.height * 0.68))

                if collapse {
                    context.stroke(chosenCyan ? cyan : violet, with: .color(chosenCyan ? .cyan : .purple), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    drawShards(context: &context, path: chosenCyan ? violet : cyan, color: chosenCyan ? .purple : .cyan)
                } else {
                    context.stroke(cyan, with: .color(.cyan.opacity(chosenCyan ? 0.95 : 0.35)), style: StrokeStyle(lineWidth: chosenCyan ? 3 : 1.5, lineCap: .round, dash: [9, 8]))
                    context.stroke(violet, with: .color(.purple.opacity(chosenCyan ? 0.35 : 0.95)), style: StrokeStyle(lineWidth: chosenCyan ? 1.5 : 3, lineCap: .round, dash: [9, 8]))
                }

                context.fill(Path(ellipseIn: CGRect(x: start.x - 8, y: start.y - 8, width: 16, height: 16)), with: .color(.cyan))
                context.fill(Path(ellipseIn: CGRect(x: end.x - 9, y: end.y - 9, width: 18, height: 18)), with: .color(.green))
            }
            .overlay {
                if step == 1 {
                    Image(systemName: "hand.tap.fill")
                        .font(.system(size: 42, weight: .light))
                        .foregroundStyle(.white.opacity(0.86))
                }
            }
        }
        .padding(14)
        .background(.white.opacity(0.025), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(.white.opacity(0.09), lineWidth: 1)
        }
    }

    private func path(start: CGPoint, control: CGPoint, end: CGPoint) -> Path {
        var result = Path()
        result.move(to: start)
        result.addQuadCurve(to: end, control: control)
        return result
    }

    private func drawOrbit(context: inout GraphicsContext, size: CGSize) {
        let diameter = min(size.width * 0.94, size.height * 0.92)
        let rect = CGRect(x: (size.width - diameter) / 2, y: (size.height - diameter) / 2, width: diameter, height: diameter)
        context.stroke(Path(ellipseIn: rect), with: .color(.purple.opacity(0.28)), lineWidth: 1.5)
    }

    private func drawHazard(context: inout GraphicsContext, center: CGPoint) {
        context.fill(Path(ellipseIn: CGRect(x: center.x - 24, y: center.y - 24, width: 48, height: 48)), with: .color(.red.opacity(0.09)))
        context.stroke(Path(ellipseIn: CGRect(x: center.x - 12, y: center.y - 12, width: 24, height: 24)), with: .color(.red), lineWidth: 2)
    }

    private func drawShards(context: inout GraphicsContext, path: Path, color: Color) {
        for index in 0..<11 {
            let x = 0.26 + Double(index) * 0.052
            let rect = CGRect(x: 60 + x * 210, y: 125 + Double(index % 3) * 10, width: 5, height: 2)
            context.fill(Path(roundedRect: rect, cornerRadius: 1), with: .color(color.opacity(0.62)))
        }
    }
}
