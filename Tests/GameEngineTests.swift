import XCTest
@testable import Collapse

final class GameEngineTests: XCTestCase {
    func testRoundGenerationIsDeterministic() {
        let generator = RoundGenerator(baseSeed: 42)
        XCTAssertEqual(generator.makeRound(index: 7), generator.makeRound(index: 7))
    }

    func testHazardSitsOnDangerousTimeline() {
        let round = RoundGenerator(baseSeed: 7).makeRound(index: 3)
        let expected = round.path(for: round.dangerBranch).point(at: round.hazard.pathProgress)
        XCTAssertEqual(round.hazard.center.x, expected.x, accuracy: 0.000_001)
        XCTAssertEqual(round.hazard.center.y, expected.y, accuracy: 0.000_001)
    }

    func testGemSitsOnSafeTimeline() {
        let round = RoundGenerator(baseSeed: 11).makeRound(index: 5)
        let expected = round.path(for: round.safeBranch).point(at: round.gem.pathProgress)
        XCTAssertEqual(round.gem.center.x, expected.x, accuracy: 0.000_001)
        XCTAssertEqual(round.gem.center.y, expected.y, accuracy: 0.000_001)
    }

    @MainActor
    func testCountdownBlocksInputAndStartsChoosingAfterGo() {
        let engine = GameEngine(seed: 99, sensory: .silent)
        engine.start(at: 100)
        XCTAssertEqual(engine.phase, .ready)
        XCTAssertEqual(engine.countdownLabel(at: 100.2), "3")
        XCTAssertEqual(engine.countdownLabel(at: 101.2), "2")
        XCTAssertEqual(engine.countdownLabel(at: 102.2), "1")
        XCTAssertEqual(engine.countdownLabel(at: 103.1), "GO")

        engine.toggleSelection()
        XCTAssertEqual(engine.selectedBranch, .cyan)
        engine.tick(at: 103.36)
        XCTAssertEqual(engine.phase, .choosing)
    }

    @MainActor
    func testChoosingSafeFutureScoresAndCollectsGem() {
        let engine = GameEngine(seed: 99, sensory: .silent)
        let choosing = beginChoosing(engine, start: 100)
        engine.selectedBranch = engine.round.safeBranch
        let commit = choosing + engine.choiceDuration + 0.01
        engine.tick(at: commit)
        engine.tick(at: commit + engine.travelDuration + 0.01)
        XCTAssertEqual(engine.score, 1)
        XCTAssertEqual(engine.economy.gems, 1)
        XCTAssertEqual(engine.state, .playing)
        XCTAssertEqual(engine.phase, .choosing)
    }

    @MainActor
    func testChoosingDangerousFutureEndsGame() {
        let engine = GameEngine(seed: 99, sensory: .silent)
        let choosing = beginChoosing(engine, start: 100)
        engine.selectedBranch = engine.round.dangerBranch
        let commit = choosing + engine.choiceDuration + 0.01
        engine.tick(at: commit)
        let collision = commit + engine.travelDuration * engine.round.hazard.pathProgress
        engine.tick(at: collision + 0.05)
        XCTAssertEqual(engine.state, .gameOver)
        XCTAssertEqual(engine.phase, .dead)
        XCTAssertEqual(engine.score, 0)
        XCTAssertEqual(engine.feedback?.kind, .collision)
    }

    @MainActor
    func testRushIsFasterThanClassic() {
        let classic = GameEngine(mode: .classic, seed: 1, sensory: .silent)
        let rush = GameEngine(mode: .rush, seed: 1, sensory: .silent)
        XCTAssertLessThan(rush.choiceDuration, classic.choiceDuration)
        XCTAssertLessThan(rush.travelDuration, classic.travelDuration)
    }

    @MainActor
    func testPrecisionAllowsOnlyOneSwitchPerRound() {
        let engine = GameEngine(mode: .precision, seed: 12, sensory: .silent)
        _ = beginChoosing(engine, start: 10)
        engine.toggleSelection()
        let afterFirst = engine.selectedBranch
        engine.toggleSelection()
        XCTAssertEqual(engine.selectedBranch, afterFirst)
    }

    @MainActor
    func testZenCollisionDoesNotEndRun() {
        let engine = GameEngine(mode: .zen, seed: 99, sensory: .silent)
        let choosing = beginChoosing(engine, start: 100)
        engine.selectedBranch = engine.round.dangerBranch
        let commit = choosing + engine.choiceDuration + 0.01
        engine.tick(at: commit)
        let collision = commit + engine.travelDuration * engine.round.hazard.pathProgress + 0.05
        engine.tick(at: collision)
        XCTAssertEqual(engine.state, .playing)
        XCTAssertEqual(engine.phase, .choosing)
        XCTAssertEqual(engine.score, 0)
    }

    func testDailySeedIsStableForCalendarDay() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let first = GameMode.daily.seed(on: date, calendar: calendar)
        let second = GameMode.daily.seed(on: date, calendar: calendar)
        XCTAssertEqual(first, second)
        XCTAssertNotEqual(first, GameMode.classic.seed(on: date, calendar: calendar))
    }

    @MainActor
    func testGuidanceQualityTracksSafeFuture() {
        let engine = GameEngine(seed: 123, sensory: .silent)
        _ = beginChoosing(engine, start: 10)
        engine.selectedBranch = engine.round.dangerBranch
        XCTAssertEqual(engine.guidanceQuality, 0, accuracy: 0.000_001)
        engine.selectedBranch = engine.round.safeBranch
        XCTAssertGreaterThan(engine.guidanceQuality, 0)
        XCTAssertLessThanOrEqual(engine.guidanceQuality, 1)
    }

    @MainActor
    func testPausePreservesCountdownClock() {
        let engine = GameEngine(seed: 5, sensory: .silent)
        engine.start(at: 100)
        engine.pause(at: 100.5)
        engine.resume(at: 200.5)
        engine.tick(at: 202.0)
        XCTAssertEqual(engine.phase, .ready)
        engine.tick(at: 203.4)
        XCTAssertEqual(engine.phase, .choosing)
    }

    @MainActor
    func testRestartResetsRunIntoCountdown() {
        let engine = GameEngine(seed: 21, sensory: .silent)
        let choosing = beginChoosing(engine, start: 100)
        engine.selectedBranch = engine.round.safeBranch
        let commit = choosing + engine.choiceDuration + 0.01
        engine.tick(at: commit)
        engine.tick(at: commit + engine.travelDuration + 0.01)
        engine.pause(at: 106)

        engine.restart(at: 200)

        XCTAssertEqual(engine.state, .playing)
        XCTAssertEqual(engine.phase, .ready)
        XCTAssertEqual(engine.score, 0)
        XCTAssertEqual(engine.economy.gems, 0)
        XCTAssertEqual(engine.travelProgress, 0)
        XCTAssertEqual(engine.countdownLabel(at: 200.1), "3")
    }

    @MainActor
    func testDailyStreakLeaderboardGemUnlockAndModePersistence() async {
        let suite = "collapse.tests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suite) else {
            XCTFail("Could not create isolated UserDefaults suite")
            return
        }
        defer { defaults.removePersistentDomain(forName: suite) }

        let profile = PlayerProfile(defaults: defaults)
        var calendar = Calendar(identifier: .gregorian)
        guard let timeZone = TimeZone(secondsFromGMT: 0) else {
            XCTFail("Could not create UTC time zone")
            return
        }
        calendar.timeZone = timeZone
        let day = Date(timeIntervalSince1970: 1_700_000_000)

        profile.selectedMode = .daily
        profile.registerRunStart(now: day, calendar: calendar)
        profile.registerRunStart(now: day, calendar: calendar)
        XCTAssertEqual(profile.dailyRunStreak, 1)

        guard let nextDay = calendar.date(byAdding: .day, value: 1, to: day) else {
            XCTFail("Could not create next day")
            return
        }
        profile.registerRunStart(now: nextDay, calendar: calendar)
        XCTAssertEqual(profile.dailyRunStreak, 2)

        await profile.record(score: 4, gemsEarned: 10)
        await profile.record(score: 9, gemsEarned: 10)
        await profile.record(score: 6, gemsEarned: 10)
        XCTAssertEqual(profile.topScores, [9, 6, 4])
        XCTAssertEqual(profile.localRank(for: 7), 2)
        XCTAssertEqual(profile.gemBalance, 30)
        XCTAssertTrue(profile.unlock(.aurora))
        XCTAssertEqual(profile.gemBalance, 5)
        XCTAssertTrue(profile.isUnlocked(.aurora, isPlusUnlocked: false))
        XCTAssertEqual(PlayerProfile(defaults: defaults).selectedMode, .daily)
    }

    @MainActor
    private func beginChoosing(_ engine: GameEngine, start: Double) -> Double {
        engine.start(at: start)
        let choosing = start + 3.36
        engine.tick(at: choosing)
        XCTAssertEqual(engine.phase, .choosing)
        return choosing
    }
}
