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
        let session = GameSession(seed: 99, haptics: .silent)
        let start = 100.0
        session.start(at: start)
        session.selectedBranch = session.round.dangerBranch.other
        let commit = start + session.choiceDuration + 0.01
        session.tick(at: commit)
        session.tick(at: commit + session.travelDuration + 0.01)
        XCTAssertEqual(session.score, 1)
        XCTAssertEqual(session.phase, .choosing)
    }

    @MainActor
    func testChoosingDangerousFutureDies() {
        let session = GameSession(seed: 99, haptics: .silent)
        let start = 100.0
        session.start(at: start)
        session.selectedBranch = session.round.dangerBranch
        let commit = start + session.choiceDuration + 0.01
        session.tick(at: commit)
        let collision = commit + session.travelDuration * session.round.hazard.pathProgress
        session.tick(at: collision + 0.05)
        XCTAssertEqual(session.phase, .dead)
        XCTAssertEqual(session.score, 0)
    }
}
