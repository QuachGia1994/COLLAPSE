import ActivityKit
import Foundation

struct RunActivityAttributes: ActivityAttributes, Sendable {
    struct ContentState: Codable, Hashable, Sendable {
        let score: Int
        let bestScore: Int
        let streak: Int
        let localRank: Int?
        let status: RunStatus
    }

    let startedAt: Date
}

enum RunStatus: String, Codable, Hashable, Sendable {
    case playing
    case paused
    case finished
}
