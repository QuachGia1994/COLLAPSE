import Foundation
import Observation

enum GameState: Equatable, Sendable {
    case ready
    case playing
    case paused
    case gameOver
}

@MainActor
@Observable
final class GameEngine {
    private static let countdownDuration = 3.35

    let mode: GameMode
    private let generator: RoundGenerator
    private var sensory: SensoryClient
    private var roundIndex = 0
    private var choiceStartedAt = 0.0
    private var travelStartedAt = 0.0
    private var countdownStartedAt = 0.0
    private var pausedAt: Double?
    private var switchesThisRound = 0

    private(set) var state: GameState = .ready
    private(set) var phase: GamePhase = .ready
    private(set) var round: RoundLayout
    private(set) var score = 0
    private(set) var travelProgress = 0.0
    private(set) var rejectedBranch: TimelineBranch?
    private(set) var collapseProgress = 0.0
    private(set) var economy = RunEconomy()
    private(set) var didCollectCurrentGem = false
    private(set) var feedback: GameFeedback?
    var selectedBranch: TimelineBranch = .cyan

    init(
        mode: GameMode = .classic,
        seed: UInt64? = nil,
        date: Date = .now,
        sensory: SensoryClient = .silent
    ) {
        self.mode = mode
        let resolvedSeed = seed ?? mode.seed(on: date)
        generator = RoundGenerator(
            baseSeed: resolvedSeed,
            hazardRadiusMultiplier: mode.hazardRadiusMultiplier
        )
        self.sensory = sensory
        round = generator.makeRound(index: 0)
    }

    var choiceDuration: Double {
        max(mode.choiceFloor, mode.choiceBase - Double(score) * mode.choiceDecay)
    }

    var travelDuration: Double {
        max(mode.travelFloor, mode.travelBase - Double(score) * mode.travelDecay)
    }

    var guidanceQuality: Double {
        let progress = round.hazard.pathProgress
        let candidate = round.path(for: selectedBranch).point(at: progress)
        let hazard = round.hazard.center
        let distance = hypot(candidate.x - hazard.x, candidate.y - hazard.y)
        let clearance = max(0, distance - round.hazard.radius)
        return min(clearance / (round.hazard.radius * 4), 1)
    }

    func countdownLabel(at requestedTime: Double? = nil) -> String? {
        guard state == .playing, phase == .ready else { return nil }
        let elapsed = max(0, (requestedTime ?? Self.now()) - countdownStartedAt)
        if elapsed < 1 { return "3" }
        if elapsed < 2 { return "2" }
        if elapsed < 3 { return "1" }
        if elapsed < Self.countdownDuration { return "GO" }
        return nil
    }

    func choiceProgress(at requestedTime: Double? = nil) -> Double {
        guard state == .playing, phase == .choosing else { return 0 }
        let time = requestedTime ?? Self.now()
        return min(max((time - choiceStartedAt) / choiceDuration, 0), 1)
    }

    func feedbackProgress(at requestedTime: Double? = nil) -> Double? {
        guard let feedback else { return nil }
        let time = requestedTime ?? Self.now()
        return min(max((time - feedback.startedAt) / 0.38, 0), 1)
    }

    func connectSensory(_ sensory: SensoryClient) {
        self.sensory.stopGuidance()
        self.sensory = sensory
        guard state == .playing, phase == .choosing else { return }
        sensory.beginGuidance(guidanceQuality)
    }

    func start(at requestedTime: Double? = nil) {
        let time = requestedTime ?? Self.now()
        score = 0
        economy.reset()
        roundIndex = 0
        round = generator.makeRound(index: roundIndex)
        selectedBranch = .cyan
        resetRoundState()
        phase = .ready
        state = .playing
        pausedAt = nil
        countdownStartedAt = time
        sensory.stopGuidance()
    }

    func toggleSelection() {
        guard state == .playing, phase == .choosing else { return }
        if let limit = mode.maxSwitchesPerRound, switchesThisRound >= limit { return }
        selectedBranch = selectedBranch.other
        switchesThisRound += 1
        sensory.updateGuidance(guidanceQuality)
    }

    func tick(at requestedTime: Double? = nil) {
        guard state == .playing else { return }
        let time = requestedTime ?? Self.now()
        expireFeedback(at: time)
        switch phase {
        case .ready:
            tickCountdown(at: time)
        case .choosing:
            guard time - choiceStartedAt >= choiceDuration else { return }
            commit(at: time)
        case .traveling:
            updateTravel(at: time)
        case .dead:
            return
        }
    }

    func pause(at requestedTime: Double? = nil) {
        guard state == .playing else { return }
        pausedAt = requestedTime ?? Self.now()
        state = .paused
        sensory.stopGuidance()
    }

    func resume(at requestedTime: Double? = nil) {
        guard state == .paused, let pausedAt else { return }
        let time = requestedTime ?? Self.now()
        shiftActiveClock(by: max(0, time - pausedAt))
        self.pausedAt = nil
        state = .playing
    }

    func restart(at requestedTime: Double? = nil) {
        sensory.stopGuidance()
        start(at: requestedTime)
    }

    private func tickCountdown(at time: Double) {
        guard time - countdownStartedAt >= Self.countdownDuration else { return }
        phase = .choosing
        choiceStartedAt = time
        sensory.beginGuidance(guidanceQuality)
    }

    private func shiftActiveClock(by pausedDuration: Double) {
        switch phase {
        case .ready:
            countdownStartedAt += pausedDuration
        case .choosing:
            choiceStartedAt += pausedDuration
            sensory.beginGuidance(guidanceQuality)
        case .traveling:
            travelStartedAt += pausedDuration
        case .dead:
            return
        }
    }

    private func commit(at time: Double) {
        rejectedBranch = selectedBranch.other
        travelStartedAt = time
        travelProgress = 0
        collapseProgress = 0
        phase = .traveling
        sensory.stopGuidance()
        sensory.commit()
    }

    private func updateTravel(at time: Double) {
        let elapsed = time - travelStartedAt
        travelProgress = min(max(elapsed / travelDuration, 0), 1)
        collapseProgress = min(max(elapsed / 0.42, 0), 1)
        collectGemIfNeeded(at: time)
        guard !didHitHazard() else {
            handleCollision(at: time)
            return
        }
        guard travelProgress >= 1 else { return }
        score += 1
        sensory.success()
        prepareNextRound(at: time)
    }

    private func didHitHazard() -> Bool {
        selectedBranch == round.dangerBranch && travelProgress >= round.hazard.pathProgress - 0.035
    }

    private func handleCollision(at time: Double) {
        guard mode.collisionEndsRun else {
            sensory.failure()
            prepareNextRound(at: time)
            return
        }
        endRun(at: time)
    }

    private func collectGemIfNeeded(at time: Double) {
        guard !didCollectCurrentGem else { return }
        guard selectedBranch == round.safeBranch else { return }
        guard travelProgress >= round.gem.pathProgress else { return }
        didCollectCurrentGem = true
        economy.collect(round.gem)
        feedback = GameFeedback(kind: .gem, startedAt: time)
        sensory.gem()
    }

    private func endRun(at time: Double) {
        phase = .dead
        state = .gameOver
        feedback = GameFeedback(kind: .collision, startedAt: time)
        sensory.failure()
    }

    private func prepareNextRound(at time: Double) {
        roundIndex += 1
        round = generator.makeRound(index: roundIndex)
        selectedBranch = score.isMultiple(of: 2) ? .cyan : .violet
        resetRoundState()
        phase = .choosing
        choiceStartedAt = time + 0.12
        sensory.beginGuidance(guidanceQuality)
    }

    private func resetRoundState() {
        travelProgress = 0
        rejectedBranch = nil
        collapseProgress = 0
        didCollectCurrentGem = false
        feedback = nil
        switchesThisRound = 0
    }

    private func expireFeedback(at time: Double) {
        guard let feedback, time - feedback.startedAt > 0.42 else { return }
        self.feedback = nil
    }

    private static func now() -> Double {
        Date.now.timeIntervalSinceReferenceDate
    }
}
