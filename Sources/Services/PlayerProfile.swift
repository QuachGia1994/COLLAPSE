import Foundation
import Observation

@MainActor
@Observable
final class PlayerProfile {
    private enum Key {
        static let tutorial = "collapse.tutorial.completed"
        static let bestScore = "collapse.best.score"
        static let skin = "collapse.skin.selected"
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

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        didCompleteTutorial = defaults.bool(forKey: Key.tutorial)
        bestScore = defaults.integer(forKey: Key.bestScore)
        selectedSkin = GameSkin(rawValue: defaults.string(forKey: Key.skin) ?? "") ?? .classic
    }

    func record(score: Int) {
        bestScore = max(bestScore, score)
    }
}
