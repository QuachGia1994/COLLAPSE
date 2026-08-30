package com.collapse.game.domain

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class GameControllerTest {
    @Test
    fun roundGenerationIsDeterministic() {
        val generator = RoundGenerator(42uL)
        assertEquals(generator.makeRound(7), generator.makeRound(7))
    }

    @Test
    fun hazardAndGemSitOnOppositeTimelines() {
        val round = RoundGenerator(7uL).makeRound(3)
        val hazard = round.path(round.dangerBranch).pointAt(round.hazard.pathProgress)
        val gem = round.path(round.safeBranch).pointAt(round.gem.pathProgress)
        assertEquals(hazard.x, round.hazard.center.x, 0.000_001)
        assertEquals(hazard.y, round.hazard.center.y, 0.000_001)
        assertEquals(gem.x, round.gem.center.x, 0.000_001)
        assertEquals(gem.y, round.gem.center.y, 0.000_001)
    }

    @Test
    fun safeFutureScoresAndCollectsGem() {
        val controller = GameController(seed = 99uL)
        val start = 100_000_000_000L
        controller.start(start)
        controller.selectedBranch = controller.round.safeBranch
        val commit = start + ((controller.choiceDurationSeconds + 0.01) * 1_000_000_000L).toLong()
        controller.tick(commit)
        val finish = commit + ((controller.travelDurationSeconds + 0.01) * 1_000_000_000L).toLong()
        controller.tick(finish)
        assertEquals(1, controller.score)
        assertEquals(1, controller.economy.gems)
        assertEquals(GameState.Playing, controller.state)
        assertEquals(GamePhase.Choosing, controller.phase)
    }

    @Test
    fun dangerousFutureEndsGame() {
        val controller = GameController(seed = 99uL)
        val start = 100_000_000_000L
        controller.start(start)
        controller.selectedBranch = controller.round.dangerBranch
        val commit = start + ((controller.choiceDurationSeconds + 0.01) * 1_000_000_000L).toLong()
        controller.tick(commit)
        val collision = commit + (controller.travelDurationSeconds * controller.round.hazard.pathProgress * 1_000_000_000L).toLong() + 60_000_000L
        controller.tick(collision)
        assertEquals(GameState.GameOver, controller.state)
        assertEquals(GamePhase.Dead, controller.phase)
        assertEquals(FeedbackKind.Collision, controller.feedback?.kind)
    }

    @Test
    fun pausedTicksDoNotAdvanceRenderClockOrDecision() {
        val controller = GameController(seed = 5uL)
        val start = 100_000_000_000L
        controller.start(start)
        controller.tick(start + 300_000_000L)
        controller.pause(start + 400_000_000L)
        val frozenClock = controller.nowNanos

        controller.tick(start + 20_000_000_000L)

        assertEquals(frozenClock, controller.nowNanos)
        assertEquals(GameState.Paused, controller.state)
        assertEquals(GamePhase.Choosing, controller.phase)
    }

    @Test
    fun pauseResumeAndRestartPreserveExpectedState() {
        val controller = GameController(seed = 21uL)
        controller.start(100_000_000_000L)
        controller.pause(100_500_000_000L)
        assertEquals(GameState.Paused, controller.state)
        controller.resume(200_500_000_000L)
        assertEquals(GameState.Playing, controller.state)
        controller.restart(300_000_000_000L)
        assertEquals(0, controller.score)
        assertEquals(0, controller.economy.gems)
        assertEquals(GamePhase.Choosing, controller.phase)
        assertTrue(controller.travelProgress == 0.0)
    }
}
