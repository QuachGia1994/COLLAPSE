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
    func testChoosingSafeFutureScoresAndCollectsGem() {
        let engine = GameEngine(seed: 99, sensory: .silent)
        let start = 100.0
        engine.start(at: start)
        engine.selectedBranch = engine.round.safeBranch
        let commit = start + engine.choiceDuration + 0.01
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
        let start = 100.0
        engine.start(at: start)
        engine.selectedBranch = engine.round.dangerBranch
        let commit = start + engine.choiceDuration + 0.01
        engine.tick(at: commit)
        let collision = commit + engine.travelDuration * engine.round.hazard.pathProgress
        engine.tick(at: collision + 0.05)
        XCTAssertEqual(engine.state, .gameOver)
        XCTAssertEqual(engine.phase, .dead)
        XCTAssertEqual(engine.score, 0)
        XCTAssertEqual(engine.feedback?.kind, .collision)
    }

    @MainActor
    func testGuidanceQualityTracksSafeFuture() {
        let engine = GameEngine(seed: 123, sensory: .silent)
        engine.start(at: 10)
        engine.selectedBranch = engine.round.dangerBranch
        XCTAssertEqual(engine.guidanceQuality, 0, accuracy: 0.000_001)
        engine.selectedBranch = engine.round.safeBranch
        XCTAssertGreaterThan(engine.guidanceQuality, 0)
        XCTAssertLessThanOrEqual(engine.guidanceQuality, 1)
    }

    @MainActor
    func testPausePreservesDecisionClock() {
        let engine = GameEngine(seed: 5, sensory: .silent)
        engine.start(at: 100)
        engine.pause(at: 100.5)
        engine.resume(at: 200.5)
        engine.tick(at: 201.0)
        XCTAssertEqual(engine.phase, .choosing)
        XCTAssertEqual(engine.state, .playing)
    }

    @MainActor
    func testRestartResetsPausedRunStateAndEconomy() {
        let engine = GameEngine(seed: 21, sensory: .silent)
        let start = 100.0
        engine.start(at: start)
        engine.selectedBranch = engine.round.safeBranch
        let commit = start + engine.choiceDuration + 0.01
        engine.tick(at: commit)
        engine.tick(at: commit + engine.travelDuration + 0.01)
        engine.pause(at: 102)

        engine.restart(at: 200)

        XCTAssertEqual(engine.state, .playing)
        XCTAssertEqual(engine.phase, .choosing)
        XCTAssertEqual(engine.score, 0)
        XCTAssertEqual(engine.economy.gems, 0)
        XCTAssertEqual(engine.travelProgress, 0)
    }

    @MainActor
    func testDailyStreakLeaderboardAndGemUnlock() async {
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
    }
}