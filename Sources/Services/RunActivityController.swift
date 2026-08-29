import ActivityKit
import Foundation
import Observation

@MainActor
@Observable
final class RunActivityController {
    @ObservationIgnored private var activity: Activity<RunActivityAttributes>?
    private(set) var isActive = false

    init() {
        activity = Activity<RunActivityAttributes>.activities.first
        isActive = activity != nil
    }

    func start(streak: Int, bestScore: Int, localRank: Int?) async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        if activity != nil {
            await update(score: 0, bestScore: bestScore, streak: streak, localRank: localRank, status: .playing)
            return
        }

        let attributes = RunActivityAttributes(startedAt: .now)
        let state = RunActivityAttributes.ContentState(
            score: 0,
            bestScore: bestScore,
            streak: streak,
            localRank: localRank,
            status: .playing
        )
        do {
            activity = try Activity.request(
                attributes: attributes,
                content: ActivityContent(state: state, staleDate: nil),
                pushType: nil
            )
            isActive = true
        } catch {
            isActive = false
        }
    }

    func update(score: Int, bestScore: Int, streak: Int, localRank: Int?, status: RunStatus) async {
        guard let activity else { return }
        let state = RunActivityAttributes.ContentState(
            score: score,
            bestScore: bestScore,
            streak: streak,
            localRank: localRank,
            status: status
        )
        await activity.update(ActivityContent(state: state, staleDate: nil))
    }

    func end(score: Int, bestScore: Int, streak: Int, localRank: Int?) async {
        guard let activity else { return }
        let state = RunActivityAttributes.ContentState(
            score: score,
            bestScore: bestScore,
            streak: streak,
            localRank: localRank,
            status: .finished
        )
        await activity.end(
            ActivityContent(state: state, staleDate: nil),
            dismissalPolicy: .default
        )
        self.activity = nil
        isActive = false
    }
}
