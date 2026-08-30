import Foundation

enum TimelineBranch: Int, CaseIterable, Hashable, Sendable {
    case cyan
    case violet

    var other: TimelineBranch { self == .cyan ? .violet : .cyan }
}

enum GamePhase: Equatable, Sendable {
    case ready
    case choosing
    case traveling
    case dead
}

struct GamePoint: Equatable, Sendable {
    let x: Double
    let y: Double
}

struct FuturePath: Equatable, Sendable {
    let start: GamePoint
    let control: GamePoint
    let end: GamePoint

    func point(at t: Double) -> GamePoint {
        let value = min(max(t, 0), 1)
        let inverse = 1 - value
        return GamePoint(
            x: inverse * inverse * start.x + 2 * inverse * value * control.x + value * value * end.x,
            y: inverse * inverse * start.y + 2 * inverse * value * control.y + value * value * end.y
        )
    }
}

struct Hazard: Equatable, Sendable {
    let center: GamePoint
    let radius: Double
    let pathProgress: Double
}

struct Gem: Equatable, Sendable {
    let center: GamePoint
    let radius: Double
    let pathProgress: Double
    let value: Int
}

struct RoundLayout: Equatable, Sendable {
    let cyanPath: FuturePath
    let violetPath: FuturePath
    let hazard: Hazard
    let gem: Gem
    let dangerBranch: TimelineBranch

    var safeBranch: TimelineBranch { dangerBranch.other }

    func path(for branch: TimelineBranch) -> FuturePath {
        branch == .cyan ? cyanPath : violetPath
    }
}

struct RunEconomy: Equatable, Sendable {
    private(set) var gems = 0

    mutating func collect(_ gem: Gem) {
        gems += gem.value
    }

    mutating func reset() {
        gems = 0
    }
}

struct GameFeedback: Equatable, Sendable {
    enum Kind: Equatable, Sendable {
        case gem
        case collision
    }

    let kind: Kind
    let startedAt: Double
}

struct SplitMix64: RandomNumberGenerator, Sendable {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var value = state
        value = (value ^ (value >> 30)) &* 0xBF58476D1CE4E5B9
        value = (value ^ (value >> 27)) &* 0x94D049BB133111EB
        return value ^ (value >> 31)
    }

    mutating func unit() -> Double {
        Double(next() >> 11) / Double(1 << 53)
    }
}

struct RoundGenerator: Sendable {
    let baseSeed: UInt64

    func makeRound(index: Int) -> RoundLayout {
        var random = SplitMix64(seed: baseSeed &+ UInt64(index) &* 0x9E3779B97F4A7C15)
        let paths = makePaths(random: &random)
        let dangerBranch: TimelineBranch = random.unit() < 0.5 ? .cyan : .violet
        let hazard = makeHazard(paths: paths, dangerBranch: dangerBranch, random: &random)
        let gem = makeGem(paths: paths, safeBranch: dangerBranch.other, random: &random)
        return RoundLayout(
            cyanPath: paths.cyan,
            violetPath: paths.violet,
            hazard: hazard,
            gem: gem,
            dangerBranch: dangerBranch
        )
    }

    private func makePaths(random: inout SplitMix64) -> (cyan: FuturePath, violet: FuturePath) {
        let startY = 0.48 + (random.unit() - 0.5) * 0.10
        let endY = 0.48 + (random.unit() - 0.5) * 0.16
        let spread = 0.22 + random.unit() * 0.06
        let start = GamePoint(x: 0.12, y: startY)
        let end = GamePoint(x: 0.88, y: endY)
        let midpoint = (startY + endY) / 2
        let cyanControl = GamePoint(x: 0.50, y: min(max(midpoint - spread, 0.18), 0.82))
        let violetControl = GamePoint(x: 0.50, y: min(max(midpoint + spread, 0.18), 0.82))
        return (
            FuturePath(start: start, control: cyanControl, end: end),
            FuturePath(start: start, control: violetControl, end: end)
        )
    }

    private func makeHazard(
        paths: (cyan: FuturePath, violet: FuturePath),
        dangerBranch: TimelineBranch,
        random: inout SplitMix64
    ) -> Hazard {
        let progress = 0.58 + random.unit() * 0.14
        let path = dangerBranch == .cyan ? paths.cyan : paths.violet
        return Hazard(center: path.point(at: progress), radius: 0.055, pathProgress: progress)
    }

    private func makeGem(
        paths: (cyan: FuturePath, violet: FuturePath),
        safeBranch: TimelineBranch,
        random: inout SplitMix64
    ) -> Gem {
        let progress = 0.42 + random.unit() * 0.12
        let path = safeBranch == .cyan ? paths.cyan : paths.violet
        return Gem(center: path.point(at: progress), radius: 0.024, pathProgress: progress, value: 1)
    }
}