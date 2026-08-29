import ActivityKit
import Foundation
import Observation

@MainActor
@Observable
final class RunActivityController {
    @ObservationIgnored private var activityID: String?
    private(set) var isActive = false

    init() {
        activityID = Activity<RunActivityAttributes>.activities.first?.id
        isActive = activityID != nil
    }

    func start(streak: Int, bestScore: Int, localRank: Int?) async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let state = Self.makeState(
            score: 0,
            bestScore: bestScore,
            streak: streak,
            localRank: localRank,
            status: .playing
        )

        if let activityID {
            await Self.updateActivity(id: activityID, state: state)
            return
        }

        do {
            let activity = try Activity.request(
                attributes: RunActivityAttributes(startedAt: .now),
                content: ActivityContent(state: state, staleDate: nil),
                pushType: nil
            )
            activityID = activity.id
            isActive = true
        } catch {
            isActive = false
        }
    }

    func update(
        score: Int,
        bestScore: Int,
        streak: Int,
        localRank: Int?,
        status: RunStatus
    ) async {
        guard let activityID else { return }
        let state = Self.makeState(
            score: score,
            bestScore: bestScore,
            streak: streak,
            localRank: localRank,
            status: status
        )
        await Self.updateActivity(id: activityID, state: state)
    }

    func end(score: Int, bestScore: Int, streak: Int, localRank: Int?) async {
        guard let activityID else { return }
        let state = Self.makeState(
            score: score,
            bestScore: bestScore,
            streak: streak,
            localRank: localRank,
            status: .finished
        )
        await Self.endActivity(id: activityID, state: state)
        self.activityID = nil
        isActive = false
    }

    private static func makeState(
        score: Int,
        bestScore: Int,
        streak: Int,
        localRank: Int?,
        status: RunStatus
    ) -> RunActivityAttributes.ContentState {
        RunActivityAttributes.ContentState(
            score: score,
            bestScore: bestScore,
            streak: streak,
            localRank: localRank,
            status: status
        )
    }

    nonisolated private static func updateActivity(
        id: String,
        state: RunActivityAttributes.ContentState
    ) async {
        guard let activity = Activity<RunActivityAttributes>.activities.first(where: { $0.id == id }) else {
            return
        }
        await activity.update(ActivityContent(state: state, staleDate: nil))
    }

    nonisolated private static func endActivity(
        id: String,
        state: RunActivityAttributes.ContentState
    ) async {
        guard let activity = Activity<RunActivityAttributes>.activities.first(where: { $0.id == id }) else {
            return
        }
        await activity.end(
            ActivityContent(state: state, staleDate: nil),
            dismissalPolicy: .default
        )
    }
}
