import Foundation
import Observation

@MainActor
@Observable
final class PlayerProfile {
    private enum Key {
        static let tutorial = "collapse.tutorial.completed"
        static let legacyBestScore = "collapse.best.score"
        static let skin = "collapse.skin.selected"
        static let dailyStreak = "collapse.daily.streak"
        static let lastRunDate = "collapse.daily.lastRun"
        static let legacyDailyBest = "collapse.daily.bestScore"
        static let legacyTopScores = "collapse.local.topScores"
        static let gemBalance = "collapse.economy.gems"
        static let unlockedSkins = "collapse.skin.unlocked"
        static let mode = "collapse.mode.selected"
        static let language = "collapse.language.selected"
        static let modeBest = "collapse.mode.best"
        static let modeDailyBest = "collapse.mode.dailyBest"
        static let modeTopScores = "collapse.mode.topScores"
        static let musicEnabled = "collapse.audio.music"
        static let soundEnabled = "collapse.audio.sound"
        static let hapticsEnabled = "collapse.audio.haptics"
    }

    private let defaults: UserDefaults
    private var modeBestScores: [String: Int]
    private var modeDailyBestScores: [String: Int]
    private var modeTopScores: [String: [Int]]

    var didCompleteTutorial: Bool {
        didSet { defaults.set(didCompleteTutorial, forKey: Key.tutorial) }
    }

    var selectedSkin: GameSkin {
        didSet { defaults.set(selectedSkin.rawValue, forKey: Key.skin) }
    }

    var selectedMode: GameMode {
        didSet { defaults.set(selectedMode.rawValue, forKey: Key.mode) }
    }

    var selectedLanguage: AppLanguage {
        didSet { defaults.set(selectedLanguage.rawValue, forKey: Key.language) }
    }

    var musicEnabled: Bool {
        didSet { defaults.set(musicEnabled, forKey: Key.musicEnabled) }
    }

    var soundEnabled: Bool {
        didSet { defaults.set(soundEnabled, forKey: Key.soundEnabled) }
    }

    var hapticsEnabled: Bool {
        didSet { defaults.set(hapticsEnabled, forKey: Key.hapticsEnabled) }
    }

    private(set) var dailyRunStreak: Int {
        didSet { defaults.set(dailyRunStreak, forKey: Key.dailyStreak) }
    }

    private(set) var lastRunDate: Date? {
        didSet { defaults.set(lastRunDate, forKey: Key.lastRunDate) }
    }

    private(set) var gemBalance: Int {
        didSet { defaults.set(gemBalance, forKey: Key.gemBalance) }
    }

    private(set) var unlockedSkinIDs: Set<String> {
        didSet { defaults.set(unlockedSkinIDs.sorted(), forKey: Key.unlockedSkins) }
    }

    var bestScore: Int { bestScore(for: selectedMode) }
    var dailyBestScore: Int { dailyBestScore(for: selectedMode) }
    var topScores: [Int] { topScores(for: selectedMode) }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        didCompleteTutorial = defaults.bool(forKey: Key.tutorial)
        selectedSkin = GameSkin(rawValue: defaults.string(forKey: Key.skin) ?? "") ?? .classic
        selectedMode = GameMode(rawValue: defaults.string(forKey: Key.mode) ?? "") ?? .classic
        selectedLanguage = AppLanguage(rawValue: defaults.string(forKey: Key.language) ?? "") ?? .systemDefault
        musicEnabled = defaults.object(forKey: Key.musicEnabled) as? Bool ?? true
        soundEnabled = defaults.object(forKey: Key.soundEnabled) as? Bool ?? true
        hapticsEnabled = defaults.object(forKey: Key.hapticsEnabled) as? Bool ?? true
        dailyRunStreak = defaults.integer(forKey: Key.dailyStreak)
        lastRunDate = defaults.object(forKey: Key.lastRunDate) as? Date
        gemBalance = defaults.integer(forKey: Key.gemBalance)
        unlockedSkinIDs = Set(defaults.stringArray(forKey: Key.unlockedSkins) ?? [])
        modeBestScores = Self.readIntDictionary(defaults, key: Key.modeBest)
        modeDailyBestScores = Self.readIntDictionary(defaults, key: Key.modeDailyBest)
        modeTopScores = Self.readScoreDictionary(defaults, key: Key.modeTopScores)
        migrateLegacyStatsIfNeeded()
    }

    func registerRunStart(now: Date = .now, calendar: Calendar = .current) {
        let today = calendar.startOfDay(for: now)
        guard let lastRunDate else {
            dailyRunStreak = 1
            modeDailyBestScores = [:]
            persistModeDailyBest()
            self.lastRunDate = today
            return
        }

        let previousDay = calendar.startOfDay(for: lastRunDate)
        guard previousDay != today else { return }
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)
        dailyRunStreak = previousDay == yesterday ? max(1, dailyRunStreak + 1) : 1
        modeDailyBestScores = [:]
        persistModeDailyBest()
        self.lastRunDate = today
    }

    func record(score: Int, gemsEarned: Int, mode: GameMode) async {
        guard mode.isCompetitive else { return }
        let key = mode.rawValue
        modeBestScores[key] = max(modeBestScores[key] ?? 0, score)
        modeDailyBestScores[key] = max(modeDailyBestScores[key] ?? 0, score)
        gemBalance += max(0, gemsEarned)
        if score > 0 {
            modeTopScores[key] = Array(((modeTopScores[key] ?? []) + [score]).sorted(by: >).prefix(3))
        }
        persistModeStats()
    }

    func bestScore(for mode: GameMode) -> Int {
        modeBestScores[mode.rawValue] ?? 0
    }

    func dailyBestScore(for mode: GameMode) -> Int {
        modeDailyBestScores[mode.rawValue] ?? 0
    }

    func topScores(for mode: GameMode) -> [Int] {
        modeTopScores[mode.rawValue] ?? []
    }

    func localRank(for score: Int, mode: GameMode? = nil) -> Int? {
        let targetMode = mode ?? selectedMode
        guard score > 0 else { return nil }
        let projected = (topScores(for: targetMode) + [score]).sorted(by: >)
        return projected.firstIndex(of: score).map { $0 + 1 }
    }

    func isUnlocked(_ skin: GameSkin, isPlusUnlocked: Bool) -> Bool {
        switch skin.access {
        case .free:
            true
        case .gems:
            unlockedSkinIDs.contains(skin.id)
        case .plus:
            isPlusUnlocked
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

    private func migrateLegacyStatsIfNeeded() {
        let key = GameMode.classic.rawValue
        if modeBestScores.isEmpty {
            let legacy = defaults.integer(forKey: Key.legacyBestScore)
            if legacy > 0 { modeBestScores[key] = legacy }
        }
        if modeDailyBestScores.isEmpty {
            let legacy = defaults.integer(forKey: Key.legacyDailyBest)
            if legacy > 0 { modeDailyBestScores[key] = legacy }
        }
        if modeTopScores.isEmpty {
            let legacy = (defaults.array(forKey: Key.legacyTopScores) as? [Int] ?? []).sorted(by: >)
            if !legacy.isEmpty { modeTopScores[key] = Array(legacy.prefix(3)) }
        }
        persistModeStats()
    }

    private func persistModeStats() {
        defaults.set(modeBestScores, forKey: Key.modeBest)
        persistModeDailyBest()
        defaults.set(modeTopScores, forKey: Key.modeTopScores)
    }

    private func persistModeDailyBest() {
        defaults.set(modeDailyBestScores, forKey: Key.modeDailyBest)
    }

    private static func readIntDictionary(_ defaults: UserDefaults, key: String) -> [String: Int] {
        guard let raw = defaults.dictionary(forKey: key) else { return [:] }
        return raw.compactMapValues { ($0 as? NSNumber)?.intValue }
    }

    private static func readScoreDictionary(_ defaults: UserDefaults, key: String) -> [String: [Int]] {
        guard let raw = defaults.dictionary(forKey: key) else { return [:] }
        return raw.reduce(into: [:]) { result, pair in
            guard let values = pair.value as? [Int] else { return }
            result[pair.key] = Array(values.sorted(by: >).prefix(3))
        }
    }
}
