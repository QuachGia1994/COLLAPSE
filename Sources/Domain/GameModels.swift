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

struct RoundLayout: Equatable, Sendable {
    let cyanPath: FuturePath
    let violetPath: FuturePath
    let hazard: Hazard
    let dangerBranch: TimelineBranch

    func path(for branch: TimelineBranch) -> FuturePath {
        branch == .cyan ? cyanPath : violetPath
    }
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
        let startY = 0.48 + (random.unit() - 0.5) * 0.10
        let endY = 0.48 + (random.unit() - 0.5) * 0.16
        let spread = 0.22 + random.unit() * 0.06
        let start = GamePoint(x: 0.12, y: startY)
        let end = GamePoint(x: 0.88, y: endY)
        let cyanControl = GamePoint(x: 0.50, y: min(max((startY + endY) / 2 - spread, 0.18), 0.82))
        let violetControl = GamePoint(x: 0.50, y: min(max((startY + endY) / 2 + spread, 0.18), 0.82))
        let cyanPath = FuturePath(start: start, control: cyanControl, end: end)
        let violetPath = FuturePath(start: start, control: violetControl, end: end)
        let dangerBranch: TimelineBranch = random.unit() < 0.5 ? .cyan : .violet
        let hazardProgress = 0.54 + random.unit() * 0.16
        let dangerousPath = dangerBranch == .cyan ? cyanPath : violetPath
        let hazard = Hazard(center: dangerousPath.point(at: hazardProgress), radius: 0.055, pathProgress: hazardProgress)
        return RoundLayout(cyanPath: cyanPath, violetPath: violetPath, hazard: hazard, dangerBranch: dangerBranch)
    }
}
