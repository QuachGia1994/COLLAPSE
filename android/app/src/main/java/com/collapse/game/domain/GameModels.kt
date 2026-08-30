package com.collapse.game.domain

enum class TimelineBranch {
    Cyan,
    Violet;

    val other: TimelineBranch
        get() = if (this == Cyan) Violet else Cyan
}

enum class GamePhase {
    Ready,
    Choosing,
    Traveling,
    Dead
}

enum class GameState {
    Ready,
    Playing,
    Paused,
    GameOver
}

data class GamePoint(val x: Double, val y: Double)

data class FuturePath(
    val start: GamePoint,
    val control: GamePoint,
    val end: GamePoint
) {
    fun pointAt(rawT: Double): GamePoint {
        val t = rawT.coerceIn(0.0, 1.0)
        val inverse = 1.0 - t
        return GamePoint(
            x = inverse * inverse * start.x + 2.0 * inverse * t * control.x + t * t * end.x,
            y = inverse * inverse * start.y + 2.0 * inverse * t * control.y + t * t * end.y
        )
    }
}

data class Hazard(
    val center: GamePoint,
    val radius: Double,
    val pathProgress: Double
)

data class Gem(
    val center: GamePoint,
    val radius: Double,
    val pathProgress: Double,
    val value: Int
)

data class RoundLayout(
    val cyanPath: FuturePath,
    val violetPath: FuturePath,
    val hazard: Hazard,
    val gem: Gem,
    val dangerBranch: TimelineBranch
) {
    val safeBranch: TimelineBranch
        get() = dangerBranch.other

    fun path(branch: TimelineBranch): FuturePath = if (branch == TimelineBranch.Cyan) cyanPath else violetPath
}

data class RunEconomy(val gems: Int = 0) {
    fun collecting(gem: Gem): RunEconomy = copy(gems = gems + gem.value)
}

enum class FeedbackKind {
    Gem,
    Collision
}

data class GameFeedback(
    val kind: FeedbackKind,
    val startedAtSeconds: Double
)

class SplitMix64(seed: ULong) {
    private var state = seed

    fun next(): ULong {
        state += 0x9E3779B97F4A7C15uL
        var value = state
        value = (value xor (value shr 30)) * 0xBF58476D1CE4E5B9uL
        value = (value xor (value shr 27)) * 0x94D049BB133111EBuL
        return value xor (value shr 31)
    }

    fun unit(): Double = (next() shr 11).toDouble() / (1uL shl 53).toDouble()
}

class RoundGenerator(
    private val baseSeed: ULong = 0xC011A953uL,
    private val hazardRadiusMultiplier: Double = 1.0,
    private val gemValue: Int = 1
) {
    fun makeRound(index: Int): RoundLayout {
        val random = SplitMix64(baseSeed + index.toULong() * 0x9E3779B97F4A7C15uL)
        val paths = makePaths(random)
        val danger = if (random.unit() < 0.5) TimelineBranch.Cyan else TimelineBranch.Violet
        return RoundLayout(
            cyanPath = paths.first,
            violetPath = paths.second,
            hazard = makeHazard(paths, danger, random),
            gem = makeGem(paths, danger.other, random),
            dangerBranch = danger
        )
    }

    private fun makePaths(random: SplitMix64): Pair<FuturePath, FuturePath> {
        val startY = 0.48 + (random.unit() - 0.5) * 0.10
        val endY = 0.48 + (random.unit() - 0.5) * 0.16
        val spread = 0.22 + random.unit() * 0.06
        val start = GamePoint(0.12, startY)
        val end = GamePoint(0.88, endY)
        val midpoint = (startY + endY) / 2.0
        val cyan = FuturePath(start, GamePoint(0.50, (midpoint - spread).coerceIn(0.18, 0.82)), end)
        val violet = FuturePath(start, GamePoint(0.50, (midpoint + spread).coerceIn(0.18, 0.82)), end)
        return cyan to violet
    }

    private fun makeHazard(
        paths: Pair<FuturePath, FuturePath>,
        danger: TimelineBranch,
        random: SplitMix64
    ): Hazard {
        val progress = 0.58 + random.unit() * 0.14
        val path = if (danger == TimelineBranch.Cyan) paths.first else paths.second
        return Hazard(
            center = path.pointAt(progress),
            radius = 0.055 * hazardRadiusMultiplier,
            pathProgress = progress
        )
    }

    private fun makeGem(
        paths: Pair<FuturePath, FuturePath>,
        safe: TimelineBranch,
        random: SplitMix64
    ): Gem {
        val progress = 0.42 + random.unit() * 0.12
        val path = if (safe == TimelineBranch.Cyan) paths.first else paths.second
        return Gem(path.pointAt(progress), radius = 0.024, pathProgress = progress, value = gemValue)
    }
}