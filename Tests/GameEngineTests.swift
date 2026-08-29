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

    @MainActor
    func testChoosingSafeFutureScores() {
        let engine = GameEngine(seed: 99, sensory: .silent)
        let start = 100.0
        engine.start(at: start)
        engine.selectedBranch = engine.round.dangerBranch.other
        let commit = start + engine.choiceDuration + 0.01
        engine.tick(at: commit)
        engine.tick(at: commit + engine.travelDuration + 0.01)
        XCTAssertEqual(engine.score, 1)
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
    }

    @MainActor
    func testGuidanceQualityTracksSafeFuture() {
        let engine = GameEngine(seed: 123, sensory: .silent)
        engine.start(at: 10)
        engine.selectedBranch = engine.round.dangerBranch
        XCTAssertEqual(engine.guidanceQuality, 0, accuracy: 0.000_001)
        engine.selectedBranch = engine.round.dangerBranch.other
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
    func testDailyStreakAndLocalLeaderboard() {
        let suite = "collapse.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let profile = PlayerProfile(defaults: defaults)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let day = Date(timeIntervalSince1970: 1_700_000_000)

        profile.registerRunStart(now: day, calendar: calendar)
        profile.registerRunStart(now: day, calendar: calendar)
        XCTAssertEqual(profile.dailyRunStreak, 1)

        let nextDay = calendar.date(byAdding: .day, value: 1, to: day)!
        profile.registerRunStart(now: nextDay, calendar: calendar)
        XCTAssertEqual(profile.dailyRunStreak, 2)

        profile.record(score: 4)
        profile.record(score: 9)
        profile.record(score: 6)
        XCTAssertEqual(profile.topScores, [9, 6, 4])
        XCTAssertEqual(profile.localRank(for: 7), 2)
    }
}
