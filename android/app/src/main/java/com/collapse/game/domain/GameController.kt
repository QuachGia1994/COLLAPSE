package com.collapse.game.domain

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableDoubleStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue

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
    seed: ULong = 0xC011A953uL,
    private var sensory: SensoryClient = SensoryClient.Silent
) {
    private val generator = RoundGenerator(seed)
    private var roundIndex = 0
    private var choiceStartedAt = 0L
    private var travelStartedAt = 0L
    private var pausedAt: Long? = null

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
        get() = maxOf(0.72, 1.45 - score * 0.045)

    val travelDurationSeconds: Double
        get() = maxOf(0.62, 0.90 - score * 0.012)

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
        phase = GamePhase.Choosing
        state = GameState.Playing
        pausedAt = null
        choiceStartedAt = atNanos
    }

    fun tick(frameNanos: Long) {
        guardPlaying() ?: return
        nowNanos = frameNanos
        expireFeedback(frameNanos)
        when (phase) {
            GamePhase.Choosing -> tickChoice(frameNanos)
            GamePhase.Traveling -> tickTravel(frameNanos)
            GamePhase.Ready, GamePhase.Dead -> Unit
        }
    }

    fun toggleSelection() {
        if (state != GameState.Playing || phase != GamePhase.Choosing) return
        selectedBranch = selectedBranch.other
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
        if (phase == GamePhase.Choosing) choiceStartedAt += pausedDuration
        if (phase == GamePhase.Traveling) travelStartedAt += pausedDuration
        nowNanos = atNanos
        pausedAt = null
        state = GameState.Playing
    }

    fun restart(atNanos: Long = nowOrFallback()) {
        start(atNanos)
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
            endRun(frameNanos)
            return
        }
        if (travelProgress < 1.0) return
        score += 1
        sensory.success()
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
    }

    private fun resetRoundState() {
        travelProgress = 0.0
        collapseProgress = 0.0
        rejectedBranch = null
        didCollectCurrentGem = false
        feedback = null
    }

    private fun expireFeedback(frameNanos: Long) {
        val current = feedback ?: return
        val elapsed = frameNanos / 1_000_000_000.0 - current.startedAtSeconds
        if (elapsed > 0.42) feedback = null
    }

    private fun guardPlaying(): Unit? = if (state == GameState.Playing) Unit else null

    private fun elapsedSeconds(start: Long, end: Long): Double = (end - start) / 1_000_000_000.0

    private fun nowOrFallback(): Long = System.nanoTime()
}