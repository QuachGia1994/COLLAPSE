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
        static let dailyBestScore = "collapse.daily.bestScore"
        static let topScores = "collapse.local.topScores"
        static let gemBalance = "collapse.economy.gems"
        static let unlockedSkins = "collapse.skin.unlocked"
    }

    private let defaults: UserDefaults

    var didCompleteTutorial: Bool {
        didSet { defaults.set(didCompleteTutorial, forKey: Key.tutorial) }
    }

    private(set) var bestScore: Int {
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

    private(set) var dailyBestScore: Int {
        didSet { defaults.set(dailyBestScore, forKey: Key.dailyBestScore) }
    }

    private(set) var topScores: [Int] {
        didSet { defaults.set(topScores, forKey: Key.topScores) }
    }

    private(set) var gemBalance: Int {
        didSet { defaults.set(gemBalance, forKey: Key.gemBalance) }
    }

    private(set) var unlockedSkinIDs: Set<String> {
        didSet { defaults.set(unlockedSkinIDs.sorted(), forKey: Key.unlockedSkins) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        didCompleteTutorial = defaults.bool(forKey: Key.tutorial)
        bestScore = defaults.integer(forKey: Key.bestScore)
        selectedSkin = GameSkin(rawValue: defaults.string(forKey: Key.skin) ?? "") ?? .classic
        dailyRunStreak = defaults.integer(forKey: Key.dailyStreak)
        lastRunDate = defaults.object(forKey: Key.lastRunDate) as? Date
        dailyBestScore = defaults.integer(forKey: Key.dailyBestScore)
        topScores = (defaults.array(forKey: Key.topScores) as? [Int] ?? []).sorted(by: >).prefix(3).map { $0 }
        gemBalance = defaults.integer(forKey: Key.gemBalance)
        unlockedSkinIDs = Set(defaults.stringArray(forKey: Key.unlockedSkins) ?? [])
    }

    func registerRunStart(now: Date = .now, calendar: Calendar = .current) {
        let today = calendar.startOfDay(for: now)
        guard let lastRunDate else {
            dailyRunStreak = 1
            dailyBestScore = 0
            self.lastRunDate = today
            return
        }

        let previousDay = calendar.startOfDay(for: lastRunDate)
        guard previousDay != today else { return }
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)
        dailyRunStreak = previousDay == yesterday ? max(1, dailyRunStreak + 1) : 1
        dailyBestScore = 0
        self.lastRunDate = today
    }

    func record(score: Int, gemsEarned: Int) async {
        bestScore = max(bestScore, score)
        dailyBestScore = max(dailyBestScore, score)
        gemBalance += max(0, gemsEarned)
        guard score > 0 else { return }
        topScores = Array((topScores + [score]).sorted(by: >).prefix(3))
    }

    func localRank(for score: Int) -> Int? {
        guard score > 0 else { return nil }
        let projected = (topScores + [score]).sorted(by: >)
        return projected.firstIndex(of: score).map { $0 + 1 }
    }

    func isUnlocked(_ skin: GameSkin, isPlusUnlocked: Bool) -> Bool {
        switch skin.access {
        case .free:
            return true
        case .gems:
            return unlockedSkinIDs.contains(skin.id)
        case .plus:
            return isPlusUnlocked
        }
    }

    func unlock(_ skin: GameSkin) -> Bool {
        guard case .gems(let cost) = skin.access else { return false }
        guard !unlockedSkinIDs.contains(skin.id) else { return true }
        guard gemBalance >= cost else { return false }
        gemBalance -= cost
        unlockedSkinIDs.insert(skin.id)
        return true
    }

    func activeSkin(isPlusUnlocked: Bool) -> GameSkin {
        guard isUnlocked(selectedSkin, isPlusUnlocked: isPlusUnlocked) else { return .classic }
        return selectedSkin
    }
}