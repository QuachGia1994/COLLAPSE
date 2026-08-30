import ActivityKit
import Foundation
import Observation

@MainActor
@Observable
final class RunActivityController {
    @ObservationIgnored private var activityID: String?
    private(set) var isActive = false

    func cleanupStaleActivities() async {
        guard activityID == nil else { return }
        let state = Self.makeState(score: 0, bestScore: 0, streak: 0, localRank: nil, status: .finished)
        await Self.endOrphanedActivities(state: state)
    }

    func start(score: Int, streak: Int, bestScore: Int, localRank: Int?) async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            activityID = nil
            isActive = false
            return
        }

        let state = Self.makeState(
            score: score,
            bestScore: bestScore,
            streak: streak,
            localRank: localRank,
            status: .playing
        )

        if let activityID, await Self.updateActivity(id: activityID, state: state) {
            isActive = true
            return
        }

        activityID = nil
        isActive = false
        await Self.endOrphanedActivities(state: finishedState(from: state))

        if let activityID, await Self.updateActivity(id: activityID, state: state) {
            isActive = true
            return
        }
        requestActivity(state: state)
    }

    func update(score: Int, bestScore: Int, streak: Int, localRank: Int?, status: RunStatus) async {
        guard let activityID else { return }
        let state = Self.makeState(
            score: score,
            bestScore: bestScore,
            streak: streak,
            localRank: localRank,
            status: status
        )
        let didUpdate = await Self.updateActivity(id: activityID, state: state)
        guard didUpdate else {
            self.activityID = nil
            isActive = false
            return
        }
        isActive = true
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
        self.activityID = nil
        isActive = false
        await Self.endActivity(id: activityID, state: state)
    }

    private func requestActivity(state: RunActivityAttributes.ContentState) {
        do {
            let activity = try Activity.request(
                attributes: RunActivityAttributes(startedAt: .now),
                content: ActivityContent(state: state, staleDate: nil),
                pushType: nil
            )
            activityID = activity.id
            isActive = true
        } catch {
            activityID = nil
            isActive = false
        }
    }

    private func finishedState(from state: RunActivityAttributes.ContentState) -> RunActivityAttributes.ContentState {
        Self.makeState(
            score: state.score,
            bestScore: state.bestScore,
            streak: state.streak,
            localRank: state.localRank,
            status: .finished
        )
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
    ) async -> Bool {
        guard let activity = Activity<RunActivityAttributes>.activities.first(where: { $0.id == id }) else {
            return false
        }
        await activity.update(ActivityContent(state: state, staleDate: nil))
        return true
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
            dismissalPolicy: .immediate
        )
    }

    nonisolated private static func endOrphanedActivities(
        state: RunActivityAttributes.ContentState
    ) async {
        for activity in Activity<RunActivityAttributes>.activities {
            await activity.end(
                ActivityContent(state: state, staleDate: nil),
                dismissalPolicy: .immediate
            )
        }
    }
}