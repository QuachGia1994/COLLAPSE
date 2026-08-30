package com.collapse.game.domain

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableDoubleStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import java.time.LocalDate

interface SensoryClient {
    fun branchChanged(quality: Double)
    fun commit()
    fun gem()
    fun success()
    fun failure()

    object Silent : SensoryClient {
        override fun branchChanged(quality: Double) = Unit
        override fun commit() = Unit
        override fun gem() = Unit
        override fun success() = Unit
        override fun failure() = Unit
    }
}

class GameController(
    val mode: GameMode = GameMode.Classic,
    seed: ULong? = null,
    date: LocalDate = LocalDate.now(),
    private var sensory: SensoryClient = SensoryClient.Silent
) {
    private val generator = RoundGenerator(
        baseSeed = seed ?: mode.seed(date),
        hazardRadiusMultiplier = mode.hazardRadiusMultiplier
    )
    private var roundIndex = 0
    private var choiceStartedAt = 0L
    private var travelStartedAt = 0L
    private var countdownStartedAt = 0L
    private var pausedAt: Long? = null
    private var switchesThisRound = 0

    var state by mutableStateOf(GameState.Ready)
        private set
    var phase by mutableStateOf(GamePhase.Ready)
        private set
    var round by mutableStateOf(generator.makeRound(0))
        private set
    var score by mutableIntStateOf(0)
        private set
    var selectedBranch by mutableStateOf(TimelineBranch.Cyan)
    var travelProgress by mutableDoubleStateOf(0.0)
        private set
    var collapseProgress by mutableDoubleStateOf(0.0)
        private set
    var rejectedBranch by mutableStateOf<TimelineBranch?>(null)
        private set
    var economy by mutableStateOf(RunEconomy())
        private set
    var didCollectCurrentGem by mutableStateOf(false)
        private set
    var feedback by mutableStateOf<GameFeedback?>(null)
        private set
    var nowNanos by mutableLongStateOf(0L)
        private set

    val choiceDurationSeconds: Double
        get() = maxOf(mode.choiceFloor, mode.choiceBase - score * mode.choiceDecay)

    val travelDurationSeconds: Double
        get() = maxOf(mode.travelFloor, mode.travelBase - score * mode.travelDecay)

    val guidanceQuality: Double
        get() {
            val progress = round.hazard.pathProgress
            val candidate = round.path(selectedBranch).pointAt(progress)
            val hazard = round.hazard.center
            val dx = candidate.x - hazard.x
            val dy = candidate.y - hazard.y
            val clearance = maxOf(0.0, kotlin.math.sqrt(dx * dx + dy * dy) - round.hazard.radius)
            return (clearance / (round.hazard.radius * 4.0)).coerceIn(0.0, 1.0)
        }

    fun connectSensory(client: SensoryClient) {
        sensory = client
    }

    fun start(atNanos: Long = nowOrFallback()) {
        nowNanos = atNanos
        roundIndex = 0
        score = 0
        economy = RunEconomy()
        round = generator.makeRound(0)
        selectedBranch = TimelineBranch.Cyan
        resetRoundState()
        phase = GamePhase.Ready
        state = GameState.Playing
        pausedAt = null
        countdownStartedAt = atNanos
    }

    fun tick(frameNanos: Long) {
        guardPlaying() ?: return
        nowNanos = frameNanos
        expireFeedback(frameNanos)
        when (phase) {
            GamePhase.Ready -> tickCountdown(frameNanos)
            GamePhase.Choosing -> tickChoice(frameNanos)
            GamePhase.Traveling -> tickTravel(frameNanos)
            GamePhase.Dead -> Unit
        }
    }

    fun toggleSelection() {
        if (state != GameState.Playing || phase != GamePhase.Choosing) return
        val limit = mode.maxSwitchesPerRound
        if (limit != null && switchesThisRound >= limit) return
        selectedBranch = selectedBranch.other
        switchesThisRound += 1
        sensory.branchChanged(guidanceQuality)
    }

    fun pause(atNanos: Long = nowOrFallback()) {
        if (state != GameState.Playing) return
        nowNanos = atNanos
        pausedAt = atNanos
        state = GameState.Paused
    }

    fun resume(atNanos: Long = nowOrFallback()) {
        val pauseStart = pausedAt ?: return
        if (state != GameState.Paused) return
        val pausedDuration = maxOf(0L, atNanos - pauseStart)
        shiftActiveClock(pausedDuration)
        nowNanos = atNanos
        pausedAt = null
        state = GameState.Playing
    }

    fun restart(atNanos: Long = nowOrFallback()) {
        start(atNanos)
    }

    fun countdownLabel(): String? {
        if (state != GameState.Playing || phase != GamePhase.Ready) return null
        val elapsed = elapsedSeconds(countdownStartedAt, nowNanos)
        return when {
            elapsed < 1.0 -> "3"
            elapsed < 2.0 -> "2"
            elapsed < 3.0 -> "1"
            elapsed < COUNTDOWN_SECONDS -> "GO"
            else -> null
        }
    }

    fun choiceRemaining(): Double {
        if (state != GameState.Playing || phase != GamePhase.Choosing || choiceStartedAt == 0L) return 0.0
        val elapsed = elapsedSeconds(choiceStartedAt, nowNanos)
        return (1.0 - elapsed / choiceDurationSeconds).coerceIn(0.0, 1.0)
    }

    fun feedbackProgress(): Double? {
        val current = feedback ?: return null
        val elapsed = nowNanos / 1_000_000_000.0 - current.startedAtSeconds
        return (elapsed / 0.38).coerceIn(0.0, 1.0)
    }

    private fun tickCountdown(frameNanos: Long) {
        if (elapsedSeconds(countdownStartedAt, frameNanos) < COUNTDOWN_SECONDS) return
        phase = GamePhase.Choosing
        choiceStartedAt = frameNanos
        sensory.branchChanged(guidanceQuality)
    }

    private fun tickChoice(frameNanos: Long) {
        if (choiceStartedAt == 0L) choiceStartedAt = frameNanos
        if (elapsedSeconds(choiceStartedAt, frameNanos) < choiceDurationSeconds) return
        rejectedBranch = selectedBranch.other
        travelStartedAt = frameNanos
        travelProgress = 0.0
        collapseProgress = 0.0
        phase = GamePhase.Traveling
        sensory.commit()
    }

    private fun tickTravel(frameNanos: Long) {
        val elapsed = elapsedSeconds(travelStartedAt, frameNanos)
        travelProgress = (elapsed / travelDurationSeconds).coerceIn(0.0, 1.0)
        collapseProgress = (elapsed / 0.42).coerceIn(0.0, 1.0)
        collectGemIfNeeded(frameNanos)
        if (didHitHazard()) {
            handleCollision(frameNanos)
            return
        }
        if (travelProgress < 1.0) return
        score += 1
        sensory.success()
        prepareNextRound(frameNanos)
    }

    private fun handleCollision(frameNanos: Long) {
        if (mode.collisionEndsRun) {
            endRun(frameNanos)
            return
        }
        sensory.failure()
        prepareNextRound(frameNanos)
    }

    private fun collectGemIfNeeded(frameNanos: Long) {
        if (didCollectCurrentGem || selectedBranch != round.safeBranch) return
        if (travelProgress < round.gem.pathProgress) return
        didCollectCurrentGem = true
        economy = economy.collecting(round.gem)
        feedback = GameFeedback(FeedbackKind.Gem, frameNanos / 1_000_000_000.0)
        sensory.gem()
    }

    private fun didHitHazard(): Boolean =
        selectedBranch == round.dangerBranch && travelProgress >= round.hazard.pathProgress - 0.035

    private fun endRun(frameNanos: Long) {
        phase = GamePhase.Dead
        state = GameState.GameOver
        feedback = GameFeedback(FeedbackKind.Collision, frameNanos / 1_000_000_000.0)
        sensory.failure()
    }

    private fun prepareNextRound(frameNanos: Long) {
        roundIndex += 1
        round = generator.makeRound(roundIndex)
        selectedBranch = if (score % 2 == 0) TimelineBranch.Cyan else TimelineBranch.Violet
        resetRoundState()
        phase = GamePhase.Choosing
        choiceStartedAt = frameNanos + 120_000_000L
        sensory.branchChanged(guidanceQuality)
    }

    private fun resetRoundState() {
        travelProgress = 0.0
        collapseProgress = 0.0
        rejectedBranch = null
        didCollectCurrentGem = false
        feedback = null
        switchesThisRound = 0
    }

    private fun shiftActiveClock(pausedDuration: Long) {
        when (phase) {
            GamePhase.Ready -> countdownStartedAt += pausedDuration
            GamePhase.Choosing -> choiceStartedAt += pausedDuration
            GamePhase.Traveling -> travelStartedAt += pausedDuration
            GamePhase.Dead -> Unit
        }
    }

    private fun expireFeedback(frameNanos: Long) {
        val current = feedback ?: return
        val elapsed = frameNanos / 1_000_000_000.0 - current.startedAtSeconds
        if (elapsed > 0.42) feedback = null
    }

    private fun guardPlaying(): Unit? = if (state == GameState.Playing) Unit else null

    private fun elapsedSeconds(start: Long, end: Long): Double = (end - start) / 1_000_000_000.0

    private fun nowOrFallback(): Long = System.nanoTime()

    private companion object {
        const val COUNTDOWN_SECONDS = 3.35
    }
}
