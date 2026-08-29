import Foundation
import Observation

@MainActor
@Observable
final class GameSession {
    private let generator: RoundGenerator
    private let haptics: HapticsClient
    private var roundIndex = 0
    private var choiceStartedAt = 0.0
    private var travelStartedAt = 0.0

    private(set) var phase: GamePhase = .ready
    private(set) var round: RoundLayout
    private(set) var score = 0
    private(set) var travelProgress = 0.0
    private(set) var rejectedBranch: TimelineBranch?
    private(set) var collapseProgress = 0.0
    var selectedBranch: TimelineBranch = .cyan

    init(seed: UInt64 = 0xC011A953, haptics: HapticsClient = .live) {
        generator = RoundGenerator(baseSeed: seed)
        self.haptics = haptics
        round = generator.makeRound(index: 0)
    }

    var choiceDuration: Double {
        max(0.72, 1.45 - Double(score) * 0.045)
    }

    var travelDuration: Double {
        max(0.62, 0.90 - Double(score) * 0.012)
    }

    var choiceProgress: Double {
        guard phase == .choosing else { return 0 }
        return min(max((Self.now() - choiceStartedAt) / choiceDuration, 0), 1)
    }

    func start(at requestedTime: Double? = nil) {
        let time = requestedTime ?? Self.now()
        score = 0
        roundIndex = 0
        round = generator.makeRound(index: roundIndex)
        selectedBranch = .cyan
        travelProgress = 0
        rejectedBranch = nil
        collapseProgress = 0
        phase = .choosing
        choiceStartedAt = time
    }

    func toggleSelection() {
        guard phase == .choosing else { return }
        selectedBranch = selectedBranch.other
        haptics.selection()
    }

    func tick(at requestedTime: Double? = nil) {
        let time = requestedTime ?? Self.now()
        switch phase {
        case .ready, .dead:
            return
        case .choosing:
            if time - choiceStartedAt >= choiceDuration {
                commit(at: time)
            }
        case .traveling:
            updateTravel(at: time)
        }
    }

    func restart(at requestedTime: Double? = nil) {
        start(at: requestedTime)
    }

    private func commit(at time: Double) {
        rejectedBranch = selectedBranch.other
        travelStartedAt = time
        travelProgress = 0
        collapseProgress = 0
        phase = .traveling
        haptics.commit()
    }

    private func updateTravel(at time: Double) {
        let elapsed = time - travelStartedAt
        travelProgress = min(max(elapsed / travelDuration, 0), 1)
        collapseProgress = min(max(elapsed / 0.42, 0), 1)

        if selectedBranch == round.dangerBranch, travelProgress >= round.hazard.pathProgress - 0.035 {
            phase = .dead
            haptics.failure()
            return
        }

        if travelProgress >= 1 {
            score += 1
            haptics.success()
            prepareNextRound(at: time)
        }
    }

    private func prepareNextRound(at time: Double) {
        roundIndex += 1
        round = generator.makeRound(index: roundIndex)
        selectedBranch = score.isMultiple(of: 2) ? .cyan : .violet
        travelProgress = 0
        rejectedBranch = nil
        collapseProgress = 0
        phase = .choosing
        choiceStartedAt = time + 0.12
    }

    private static func now() -> Double {
        ProcessInfo.processInfo.systemUptime
    }
}
