import Foundation
import Observation

@MainActor
@Observable
final class PlayerProfile {
    private enum Key {
        static let tutorial = "collapse.tutorial.completed"
        static let bestScore = "collapse.best.score"
        static let skin = "collapse.skin.selected"
        static let dailyStreak = "collapse.daily.streak"
        static let lastRunDate = "collapse.daily.lastRun"
        static let topScores = "collapse.local.topScores"
    }

    private let defaults: UserDefaults

    var didCompleteTutorial: Bool {
        didSet { defaults.set(didCompleteTutorial, forKey: Key.tutorial) }
    }

    var bestScore: Int {
        didSet { defaults.set(bestScore, forKey: Key.bestScore) }
    }

    var selectedSkin: GameSkin {
        didSet { defaults.set(selectedSkin.rawValue, forKey: Key.skin) }
    }

    private(set) var dailyRunStreak: Int {
        didSet { defaults.set(dailyRunStreak, forKey: Key.dailyStreak) }
    }

    private(set) var lastRunDate: Date? {
        didSet { defaults.set(lastRunDate, forKey: Key.lastRunDate) }
    }

    private(set) var topScores: [Int] {
        didSet { defaults.set(topScores, forKey: Key.topScores) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        didCompleteTutorial = defaults.bool(forKey: Key.tutorial)
        bestScore = defaults.integer(forKey: Key.bestScore)
        selectedSkin = GameSkin(rawValue: defaults.string(forKey: Key.skin) ?? "") ?? .classic
        dailyRunStreak = defaults.integer(forKey: Key.dailyStreak)
        lastRunDate = defaults.object(forKey: Key.lastRunDate) as? Date
        topScores = (defaults.array(forKey: Key.topScores) as? [Int] ?? []).sorted(by: >).prefix(3).map { $0 }
    }

    func registerRunStart(now: Date = .now, calendar: Calendar = .current) {
        let today = calendar.startOfDay(for: now)
        guard let lastRunDate else {
            dailyRunStreak = 1
            self.lastRunDate = today
            return
        }

        let previousDay = calendar.startOfDay(for: lastRunDate)
        if previousDay == today {
            return
        }

        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)
        dailyRunStreak = previousDay == yesterday ? max(1, dailyRunStreak + 1) : 1
        self.lastRunDate = today
    }

    func record(score: Int) {
        bestScore = max(bestScore, score)
        guard score > 0 else { return }
        topScores = Array((topScores + [score]).sorted(by: >).prefix(3))
    }

    func localRank(for score: Int) -> Int? {
        guard score > 0 else { return nil }
        let projected = (topScores + [score]).sorted(by: >)
        return projected.firstIndex(of: score).map { $0 + 1 }
    }
}
