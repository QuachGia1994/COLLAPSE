import ActivityKit
import SwiftUI
import WidgetKit

@main
struct CollapseWidgetBundle: WidgetBundle {
    var body: some Widget {
        CollapseRunLiveActivity()
    }
}

struct CollapseRunLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RunActivityAttributes.self) { context in
            LockScreenRunView(context: context)
                .activityBackgroundTint(Color.black.opacity(0.82))
                .activitySystemActionForegroundColor(.cyan)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    metric(title: "CHUỖI", value: "🔥 \(context.state.streak)")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    metric(title: "HẠNG", value: rankText(context.state.localRank))
                }
                DynamicIslandExpandedRegion(.center) {
                    Text("COLLAPSE")
                        .font(.caption.weight(.semibold))
                        .tracking(2)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        metric(title: "ĐIỂM", value: "\(context.state.score)")
                        Spacer()
                        metric(title: "KỶ LỤC", value: "\(context.state.bestScore)")
                    }
                }
            } compactLeading: {
                Text("🔥\(context.state.streak)")
                    .font(.caption2.monospacedDigit())
            } compactTrailing: {
                Text("\(context.state.score)")
                    .font(.caption2.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.cyan)
            } minimal: {
                Circle()
                    .fill(.cyan)
                    .overlay {
                        Text("C")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.black)
                    }
            }
            .keylineTint(.cyan)
        }
    }

    private func metric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(value)
                .font(.headline.monospacedDigit())
            Text(title)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }

    private func rankText(_ rank: Int?) -> String {
        rank.map { "#\($0)" } ?? "—"
    }
}

private struct LockScreenRunView: View {
    let context: ActivityViewContext<RunActivityAttributes>

    var body: some View {
        HStack(spacing: 18) {
            VStack(alignment: .leading, spacing: 5) {
                Text("COLLAPSE")
                    .font(.caption.weight(.semibold))
                    .tracking(2)
                Text(statusText)
                    .font(.title3.weight(.semibold))
            }

            Spacer()

            miniMetric("🔥", value: "\(context.state.streak)")
            miniMetric("#", value: context.state.localRank.map { String($0) } ?? "—")
            miniMetric("ĐIỂM", value: "\(context.state.score)")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var statusText: String {
        switch context.state.status {
        case .playing: "Đang chọn tương lai"
        case .paused: "Đã tạm dừng"
        case .finished: "Daily Run hoàn tất"
        }
    }

    private func miniMetric(_ title: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline.monospacedDigit())
            Text(title)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }
}
