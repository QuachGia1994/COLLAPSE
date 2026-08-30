import Foundation
import GameKit
import Observation
import SwiftUI
import UIKit

enum LeaderboardConnectionState: Equatable, Sendable {
    case unavailable
    case needsAuthentication
    case connecting
    case connected
}

@MainActor
@Observable
final class GameCenterStore {
    private enum Key {
        static let pendingScores = "collapse.gamecenter.pendingScores"
    }

    private let defaults: UserDefaults
    private var pendingScores: [String: Int]
    private(set) var state: LeaderboardConnectionState = .connecting
    private(set) var remoteRanks: [String: Int] = [:]
    private(set) var lastError: String?
    var authenticationController: UIViewController?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        pendingScores = Self.readIntDictionary(defaults, key: Key.pendingScores)
    }

    var isConnected: Bool {
        state == .connected && GKLocalPlayer.local.isAuthenticated
    }

    func start() {
        state = .connecting
        GKLocalPlayer.local.authenticateHandler = { [weak self] controller, error in
            Task { @MainActor [weak self] in
                self?.handleAuthentication(controller: controller, error: error)
            }
        }
    }

    func dismissAuthenticationController() {
        authenticationController = nil
        Task { await refreshAllCompetitiveModes() }
    }

    func refresh(mode: GameMode) async {
        guard mode.isCompetitive, let leaderboardID = mode.gameCenterLeaderboardID else {
            remoteRanks.removeValue(forKey: mode.rawValue)
            return
        }
        guard isConnected else { return }

        do {
            let leaderboard = try await loadLeaderboard(id: leaderboardID)
            let result = try await leaderboard.loadEntries(
                for: .global,
                timeScope: .allTime,
                range: NSRange(location: 1, length: 1)
            )
            remoteRanks[mode.rawValue] = result.0?.rank
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    func submit(score: Int, mode: GameMode) async {
        guard score > 0, mode.isCompetitive, let leaderboardID = mode.gameCenterLeaderboardID else { return }
        guard isConnected else {
            queue(score: score, mode: mode)
            return
        }

        do {
            let leaderboard = try await loadLeaderboard(id: leaderboardID)
            try await leaderboard.submitScore(score, context: 0, player: GKLocalPlayer.local)
            pendingScores.removeValue(forKey: mode.rawValue)
            persistPendingScores()
            await refresh(mode: mode)
        } catch {
            queue(score: score, mode: mode)
            lastError = error.localizedDescription
        }
    }

    func remoteRank(for mode: GameMode) -> Int? {
        remoteRanks[mode.rawValue]
    }

    func retryPending() async {
        guard isConnected else { return }
        let snapshot = pendingScores
        for (rawMode, score) in snapshot {
            guard let mode = GameMode(rawValue: rawMode) else { continue }
            await submit(score: score, mode: mode)
        }
    }

    private func handleAuthentication(controller: UIViewController?, error: Error?) {
        if let controller {
            authenticationController = controller
            state = .needsAuthentication
            return
        }
        authenticationController = nil

        guard error == nil, GKLocalPlayer.local.isAuthenticated else {
            state = .unavailable
            lastError = error?.localizedDescription
            return
        }

        state = .connected
        lastError = nil
        Task {
            await retryPending()
            await refreshAllCompetitiveModes()
        }
    }

    private func refreshAllCompetitiveModes() async {
        guard isConnected else { return }
        for mode in GameMode.allCases where mode.isCompetitive {
            await refresh(mode: mode)
        }
    }

    private func loadLeaderboard(id: String) async throws -> GKLeaderboard {
        let leaderboards = try await GKLeaderboard.loadLeaderboards(IDs: [id])
        guard let leaderboard = leaderboards.first else {
            throw GameCenterError.missingLeaderboard(id)
        }
        return leaderboard
    }

    private func queue(score: Int, mode: GameMode) {
        pendingScores[mode.rawValue] = max(pendingScores[mode.rawValue] ?? 0, score)
        persistPendingScores()
    }

    private func persistPendingScores() {
        defaults.set(pendingScores, forKey: Key.pendingScores)
    }

    private static func readIntDictionary(_ defaults: UserDefaults, key: String) -> [String: Int] {
        guard let raw = defaults.dictionary(forKey: key) else { return [:] }
        return raw.compactMapValues { ($0 as? NSNumber)?.intValue }
    }
}

enum GameCenterError: LocalizedError {
    case missingLeaderboard(String)

    var errorDescription: String? {
        switch self {
        case .missingLeaderboard(let id):
            "Game Center leaderboard is not configured: \(id)"
        }
    }
}

struct GameCenterAuthenticationView: UIViewControllerRepresentable {
    let controller: UIViewController

    func makeUIViewController(context: Context) -> UIViewController {
        controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
