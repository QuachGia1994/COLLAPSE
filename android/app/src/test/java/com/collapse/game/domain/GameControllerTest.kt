package com.collapse.game.domain

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.LocalDate

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
    fun countdownBlocksInputAndStartsChoosingAfterGo() {
        val controller = GameController(seed = 99uL)
        val start = 100_000_000_000L
        controller.start(start)
        assertEquals(GamePhase.Ready, controller.phase)
        controller.tick(start + 200_000_000L)
        assertEquals("3", controller.countdownLabel())
        controller.toggleSelection()
        assertEquals(TimelineBranch.Cyan, controller.selectedBranch)
        controller.tick(start + 3_360_000_000L)
        assertEquals(GamePhase.Choosing, controller.phase)
    }

    @Test
    fun safeFutureScoresAndCollectsGem() {
        val controller = GameController(seed = 99uL)
        val choosing = beginChoosing(controller, 100_000_000_000L)
        controller.selectedBranch = controller.round.safeBranch
        val commit = choosing + ((controller.choiceDurationSeconds + 0.01) * 1_000_000_000L).toLong()
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
        val choosing = beginChoosing(controller, 100_000_000_000L)
        controller.selectedBranch = controller.round.dangerBranch
        val commit = choosing + ((controller.choiceDurationSeconds + 0.01) * 1_000_000_000L).toLong()
        controller.tick(commit)
        val collision = commit + (controller.travelDurationSeconds * controller.round.hazard.pathProgress * 1_000_000_000L).toLong() + 60_000_000L
        controller.tick(collision)
        assertEquals(GameState.GameOver, controller.state)
        assertEquals(GamePhase.Dead, controller.phase)
        assertEquals(FeedbackKind.Collision, controller.feedback?.kind)
    }

    @Test
    fun rushIsFasterThanClassic() {
        val classic = GameController(mode = GameMode.Classic, seed = 1uL)
        val rush = GameController(mode = GameMode.Rush, seed = 1uL)
        assertTrue(rush.choiceDurationSeconds < classic.choiceDurationSeconds)
        assertTrue(rush.travelDurationSeconds < classic.travelDurationSeconds)
    }

    @Test
    fun precisionAllowsOneSwitchPerRound() {
        val controller = GameController(mode = GameMode.Precision, seed = 5uL)
        beginChoosing(controller, 100_000_000_000L)
        controller.toggleSelection()
        val afterFirst = controller.selectedBranch
        controller.toggleSelection()
        assertEquals(afterFirst, controller.selectedBranch)
    }

    @Test
    fun zenCollisionKeepsRunAlive() {
        val controller = GameController(mode = GameMode.Zen, seed = 99uL)
        val choosing = beginChoosing(controller, 100_000_000_000L)
        controller.selectedBranch = controller.round.dangerBranch
        val commit = choosing + ((controller.choiceDurationSeconds + 0.01) * 1_000_000_000L).toLong()
        controller.tick(commit)
        val collision = commit + (controller.travelDurationSeconds * controller.round.hazard.pathProgress * 1_000_000_000L).toLong() + 60_000_000L
        controller.tick(collision)
        assertEquals(GameState.Playing, controller.state)
        assertEquals(GamePhase.Choosing, controller.phase)
        assertEquals(0, controller.score)
    }

    @Test
    fun dailySeedIsStableForCalendarDay() {
        val day = LocalDate.of(2026, 8, 30)
        val first = GameMode.Daily.seed(day)
        val second = GameMode.Daily.seed(day)
        assertEquals(first, second)
        assertNotEquals(first, GameMode.Classic.seed(day))
    }

    @Test
    fun pauseResumePreservesCountdownAndRestartResets() {
        val controller = GameController(seed = 21uL)
        val start = 100_000_000_000L
        controller.start(start)
        controller.pause(start + 500_000_000L)
        controller.resume(start + 100_500_000_000L)
        controller.tick(start + 102_000_000_000L)
        assertEquals(GamePhase.Ready, controller.phase)
        controller.tick(start + 103_400_000_000L)
        assertEquals(GamePhase.Choosing, controller.phase)

        controller.restart(start + 200_000_000_000L)
        assertEquals(0, controller.score)
        assertEquals(0, controller.economy.gems)
        assertEquals(GamePhase.Ready, controller.phase)
        assertEquals("3", controller.countdownLabel())
    }

    private fun beginChoosing(controller: GameController, start: Long): Long {
        controller.start(start)
        val choosing = start + 3_360_000_000L
        controller.tick(choosing)
        assertEquals(GamePhase.Choosing, controller.phase)
        return choosing
    }
}
