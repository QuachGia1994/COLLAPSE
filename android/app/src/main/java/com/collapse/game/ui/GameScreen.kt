package com.collapse.game.ui

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.IconButton
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.lifecycle.compose.LocalLifecycleOwner
import com.collapse.game.R
import com.collapse.game.domain.FeedbackKind
import com.collapse.game.domain.FuturePath
import com.collapse.game.domain.GameController
import com.collapse.game.domain.GameMode
import com.collapse.game.domain.GamePhase
import com.collapse.game.domain.GamePoint
import com.collapse.game.domain.GameState
import com.collapse.game.domain.TimelineBranch
import com.collapse.game.services.PlayGamesStore
import com.collapse.game.services.PlayerProfile
import com.collapse.game.services.SensoryEngine
import kotlinx.coroutines.isActive
import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.sin

@Composable
fun GameScreen(
    profile: PlayerProfile,
    sensory: SensoryEngine,
    playGames: PlayGamesStore,
    mode: GameMode,
    isPlusUnlocked: Boolean,
    onHome: () -> Unit
) {
    val controller = remember(mode) { GameController(mode = mode) }
    val lifecycleOwner = LocalLifecycleOwner.current
    var recordedGameOver by remember { mutableStateOf(false) }
    var pausedByLifecycle by remember { mutableStateOf(false) }
    val skin = profile.activeSkin(isPlusUnlocked)

    LaunchedEffect(Unit) {
        controller.connectSensory(sensory)
        profile.registerRunStart()
        controller.start()
        while (isActive) withFrameNanos(controller::tick)
    }

    LaunchedEffect(controller.state) {
        if (controller.state != GameState.GameOver || recordedGameOver) return@LaunchedEffect
        profile.record(controller.score, controller.economy.gems, mode)
        playGames.submit(controller.score, mode)
        recordedGameOver = true
    }

    BackHandler {
        if (controller.state == GameState.Playing) {
            controller.pause()
        } else {
            onHome()
        }
    }

    DisposableEffect(lifecycleOwner) {
        val observer = LifecycleEventObserver { _, event ->
            when (event) {
                Lifecycle.Event.ON_PAUSE -> if (controller.state == GameState.Playing) {
                    pausedByLifecycle = true
                    controller.pause()
                }
                Lifecycle.Event.ON_RESUME -> if (pausedByLifecycle && controller.state == GameState.Paused) {
                    pausedByLifecycle = false
                    controller.resume()
                }
                else -> Unit
            }
        }
        lifecycleOwner.lifecycle.addObserver(observer)
        onDispose { lifecycleOwner.lifecycle.removeObserver(observer) }
    }

    val overlayActive = controller.state != GameState.Playing
    Box(
        Modifier
            .fillMaxSize()
            .background(Brush.radialGradient(listOf(skin.palette.backgroundTop, skin.palette.backgroundBottom)))
    ) {
        GameCanvas(
            controller = controller,
            skin = skin,
            interactive = !overlayActive,
            modifier = Modifier
                .fillMaxSize()
                .alpha(if (overlayActive) 0.10f else 1f)
        )
        if (!overlayActive) GameHud(controller, profile, skin)
        if (controller.state == GameState.Playing && controller.phase == GamePhase.Ready) {
            CountdownOverlay(controller, skin)
        }
        if (controller.state == GameState.Paused) {
            OverlayShade()
            PauseOverlay(
                skin = skin,
                onResume = controller::resume,
                onRestart = {
                    recordedGameOver = false
                    profile.registerRunStart()
                    controller.restart()
                },
                onHome = onHome
            )
        }
        if (controller.state == GameState.GameOver) {
            OverlayShade()
            GameOverOverlay(
                controller = controller,
                profile = profile,
                skin = skin,
                onRestart = {
                    recordedGameOver = false
                    profile.registerRunStart()
                    controller.restart()
                },
                onHome = onHome
            )
        }
    }
}

@Composable
private fun GameHud(controller: GameController, profile: PlayerProfile, skin: GameSkin) {
    Column(Modifier.fillMaxSize().padding(horizontal = 14.dp, vertical = 34.dp)) {
        GlassSurface(Modifier.fillMaxWidth(), radius = 24.dp) {
            Row(
                Modifier.fillMaxWidth().padding(12.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(5.dp)) {
                    CollapseBrandMark(skin.palette.primary, subtitle = "", compact = true)
                    Text(controller.mode.title, color = Color.White.copy(alpha = 0.48f), fontSize = 9.sp, fontWeight = FontWeight.SemiBold, letterSpacing = 1.4.sp)
                    Text("◉ ${stringResource(R.string.game_forecast)} ${"%.1f".format(controller.choiceDurationSeconds)}s", color = skin.palette.primary, fontSize = 10.sp, fontWeight = FontWeight.SemiBold, letterSpacing = 1.2.sp)
                    Text("🔥 ${profile.dailyRunStreak}  ·  ◆ ${profile.gemBalance + controller.economy.gems}", color = Color.White.copy(alpha = 0.62f), fontSize = 10.sp)
                }
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Text(controller.score.toString(), color = Color.White, fontSize = 34.sp, fontWeight = FontWeight.SemiBold)
                    Text(stringResource(R.string.game_score), color = Color.White.copy(alpha = 0.46f), fontSize = 9.sp, letterSpacing = 1.6.sp)
                }
                Spacer(Modifier.size(8.dp))
                IconButton(
                    onClick = controller::pause,
                    enabled = controller.state == GameState.Playing && controller.phase != GamePhase.Ready,
                    modifier = Modifier
                        .size(48.dp)
                        .border(1.dp, Color.White.copy(alpha = 0.35f), CircleShape)
                        .alpha(if (controller.phase == GamePhase.Ready) 0f else 1f)
                ) {
                    Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                        Box(Modifier.size(width = 3.dp, height = 15.dp).background(skin.palette.primary, RoundedCornerShape(2.dp)))
                        Box(Modifier.size(width = 3.dp, height = 15.dp).background(skin.palette.primary, RoundedCornerShape(2.dp)))
                    }
                }
            }
        }
        Spacer(Modifier.weight(1f))
        if (controller.phase == GamePhase.Choosing && controller.state == GameState.Playing) {
            GlassSurface(Modifier.align(Alignment.CenterHorizontally), radius = 99.dp) {
                Text(
                    "●  ${stringResource(R.string.game_tap)}",
                    modifier = Modifier.padding(horizontal = 16.dp, vertical = 10.dp),
                    color = if (controller.guidanceQuality > 0.5) Color(0xFF62F58D) else Color(0xFFFF5D67),
                    fontSize = 10.sp,
                    fontWeight = FontWeight.SemiBold,
                    letterSpacing = 1.2.sp
                )
            }
        }
    }
}

@Composable
private fun CountdownOverlay(controller: GameController, skin: GameSkin) {
    Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        Box(
            Modifier
                .size(118.dp)
                .background(Color.White.copy(alpha = 0.08f), CircleShape)
                .border(1.dp, skin.palette.primary.copy(alpha = 0.34f), CircleShape),
            contentAlignment = Alignment.Center
        ) {
            Text(
                controller.countdownLabel().orEmpty(),
                color = Color.White,
                fontSize = 50.sp,
                fontWeight = FontWeight.Bold
            )
        }
    }
}

@Composable
private fun PauseOverlay(
    skin: GameSkin,
    onResume: () -> Unit,
    onRestart: () -> Unit,
    onHome: () -> Unit
) {
    Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        GlassSurface(modifier = Modifier.fillMaxWidth(0.88f), radius = 28.dp) {
            Column(
                Modifier.padding(22.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                CollapseBrandMark(skin.palette.primary, subtitle = stringResource(R.string.game_pause_title), compact = true)
                Button(onClick = onResume, modifier = Modifier.fillMaxWidth(), colors = ButtonDefaults.buttonColors(containerColor = skin.palette.primary)) {
                    Text(stringResource(R.string.game_resume), color = Color.Black)
                }
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    OutlinedButton(onClick = onRestart, modifier = Modifier.weight(1f)) { Text(stringResource(R.string.game_restart)) }
                    OutlinedButton(onClick = onHome, modifier = Modifier.weight(1f)) { Text(stringResource(R.string.game_home)) }
                }
            }
        }
    }
}

@Composable
private fun GameOverOverlay(
    controller: GameController,
    profile: PlayerProfile,
    skin: GameSkin,
    onRestart: () -> Unit,
    onHome: () -> Unit
) {
    Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        GlassSurface(Modifier.fillMaxWidth(0.91f), radius = 28.dp) {
            Column(
                Modifier.padding(22.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(13.dp)
            ) {
                CollapseBrandMark(skin.palette.danger, subtitle = stringResource(R.string.game_over_title), compact = true)
                Text(stringResource(R.string.game_over_message), color = Color.White.copy(alpha = 0.56f), textAlign = TextAlign.Center, fontSize = 14.sp)
                Row(Modifier.fillMaxWidth()) {
                    MetricBlock(stringResource(R.string.game_score), controller.score.toString(), Modifier.weight(1f))
                    MetricBlock(stringResource(R.string.game_gem), "+${controller.economy.gems}", Modifier.weight(1f))
                    MetricBlock(stringResource(R.string.game_best), maxOf(profile.bestScore(controller.mode), controller.score).toString(), Modifier.weight(1f))
                }
                Button(onClick = onRestart, modifier = Modifier.fillMaxWidth(), colors = ButtonDefaults.buttonColors(containerColor = skin.palette.primary)) {
                    Text(stringResource(R.string.game_restart), color = Color.Black)
                }
                OutlinedButton(onClick = onHome, modifier = Modifier.fillMaxWidth()) { Text(stringResource(R.string.game_home)) }
            }
        }
    }
}

@Composable
private fun OverlayShade() {
    Box(
        Modifier
            .fillMaxSize()
            .background(Color.Black.copy(alpha = 0.80f))
            .pointerInput(Unit) { detectTapGestures { } }
    )
}

@Composable
private fun GameCanvas(
    controller: GameController,
    skin: GameSkin,
    interactive: Boolean,
    modifier: Modifier
) {
    val inputModifier = if (interactive) {
        modifier.pointerInput(controller.phase) {
            detectTapGestures {
                if (controller.phase == GamePhase.Choosing) controller.toggleSelection()
            }
        }
    } else {
        modifier
    }
    Canvas(inputModifier) {
        val round = controller.round
        val cyan = screenPath(round.cyanPath, size.width, size.height)
        val violet = screenPath(round.violetPath, size.width, size.height)
        drawFuturePaths(controller, skin, cyan, violet)
        drawHazard(round.hazard.center, round.hazard.radius, skin, controller.nowNanos)
        drawGem(round.gem.center, round.gem.radius, skin, controller)
        drawPortal(round.cyanPath.end, skin)
        drawGhosts(controller, skin)
        drawPlayer(controller, skin)
        if (controller.state == GameState.Playing) drawFeedback(controller, skin)
    }
}

private fun androidx.compose.ui.graphics.drawscope.DrawScope.drawFuturePaths(
    controller: GameController,
    skin: GameSkin,
    cyan: Path,
    violet: Path
) {
    drawFutureBranch(controller, skin, TimelineBranch.Cyan, controller.round.cyanPath, cyan)
    drawFutureBranch(controller, skin, TimelineBranch.Violet, controller.round.violetPath, violet)
}

private fun androidx.compose.ui.graphics.drawscope.DrawScope.drawFutureBranch(
    controller: GameController,
    skin: GameSkin,
    branch: TimelineBranch,
    future: FuturePath,
    path: Path
) {
    val selected = controller.selectedBranch == branch
    val collapse = if (controller.rejectedBranch == branch) controller.collapseProgress else 0.0
    val alpha = ((if (selected) 0.92 else 0.28) * (1.0 - collapse)).toFloat()
    val color = if (branch == TimelineBranch.Cyan) skin.palette.primary else skin.palette.secondary
    drawPath(path, color.copy(alpha = alpha), style = Stroke(width = if (selected) 3.2.dp.toPx() else 1.8.dp.toPx(), cap = StrokeCap.Round))
    for (index in 0..28) {
        val progress = index / 28.0
        val center = future.pointAt(progress).toOffset(size.width, size.height)
        val radius = if (selected && index % 2 == 0) 2.6.dp.toPx() else 1.8.dp.toPx()
        drawCircle(color.copy(alpha = alpha), radius, center)
    }
}

private fun androidx.compose.ui.graphics.drawscope.DrawScope.drawHazard(
    point: GamePoint,
    radiusValue: Double,
    skin: GameSkin,
    nowNanos: Long
) {
    val center = point.toOffset(size.width, size.height)
    val time = nowNanos / 1_000_000_000.0
    val baseRadius = size.minDimension * radiusValue.toFloat()
    val radius = baseRadius * (1f + (sin(time * 8.0) * 0.07).toFloat())
    drawCircle(skin.palette.danger.copy(alpha = 0.045f), radius * 2.25f, center)
    drawCircle(skin.palette.danger.copy(alpha = 0.12f), radius * 1.45f, center)
    drawCircle(skin.palette.danger.copy(alpha = 0.95f), radius, center, style = Stroke(width = 2.2.dp.toPx()))
    for (index in 0 until 8) {
        val angle = index / 8.0 * PI * 2.0
        val inner = Offset(center.x + (cos(angle) * radius * 0.72).toFloat(), center.y + (sin(angle) * radius * 0.72).toFloat())
        val outer = Offset(center.x + (cos(angle) * radius * 0.965).toFloat(), center.y + (sin(angle) * radius * 0.965).toFloat())
        drawLine(skin.palette.danger.copy(alpha = 0.88f), inner, outer, strokeWidth = 2.dp.toPx(), cap = StrokeCap.Round)
    }
}

private fun androidx.compose.ui.graphics.drawscope.DrawScope.drawGem(point: GamePoint, radiusValue: Double, skin: GameSkin, controller: GameController) {
    if (controller.didCollectCurrentGem) return
    val center = point.toOffset(size.width, size.height)
    val time = controller.nowNanos / 1_000_000_000.0
    val pulse = 1f + (sin(time * 10.0) * 0.12).toFloat()
    val radius = size.minDimension * radiusValue.toFloat() * pulse
    val diamond = Path().apply {
        moveTo(center.x, center.y - radius)
        lineTo(center.x + radius * 0.78f, center.y)
        lineTo(center.x, center.y + radius)
        lineTo(center.x - radius * 0.78f, center.y)
        close()
    }
    drawPath(diamond, skin.palette.safe.copy(alpha = 0.82f))
    drawPath(diamond, Color.White.copy(alpha = 0.82f), style = Stroke(width = 1.2.dp.toPx()))
}

private fun androidx.compose.ui.graphics.drawscope.DrawScope.drawPortal(point: GamePoint, skin: GameSkin) {
    val center = point.toOffset(size.width, size.height)
    drawCircle(skin.palette.safe.copy(alpha = 0.17f), 22f, center)
    drawCircle(skin.palette.safe, 10f, center, style = Stroke(width = 3f))
}

private fun androidx.compose.ui.graphics.drawscope.DrawScope.drawGhosts(controller: GameController, skin: GameSkin) {
    if (controller.phase != GamePhase.Choosing) return
    val time = controller.nowNanos / 1_000_000_000.0
    val pulse = 1f + (sin(time * skin.pulseFrequency * PI * 2.0) * skin.pulseDepth).toFloat()
    TimelineBranch.entries.forEach { branch ->
        val selected = controller.selectedBranch == branch
        val color = if (branch == TimelineBranch.Cyan) skin.palette.primary else skin.palette.secondary
        val alpha = if (selected) 0.72f else 0.22f
        listOf(0.27, 0.50, 0.74).forEach { progress ->
            val center = controller.round.path(branch).pointAt(progress).toOffset(size.width, size.height)
            drawCircle(color.copy(alpha = alpha * 0.36f), 8.5.dp.toPx() * pulse, center)
            drawCircle(color.copy(alpha = alpha), 5.5.dp.toPx() * pulse, center)
        }
    }
}

private fun androidx.compose.ui.graphics.drawscope.DrawScope.drawPlayer(controller: GameController, skin: GameSkin) {
    val point = if (controller.phase == GamePhase.Choosing) controller.round.cyanPath.start else controller.round.path(controller.selectedBranch).pointAt(controller.travelProgress)
    val center = point.toOffset(size.width, size.height)
    val color = if (controller.selectedBranch == TimelineBranch.Cyan) skin.palette.primary else skin.palette.secondary
    val time = controller.nowNanos / 1_000_000_000.0
    val pulse = 1f + (sin(time * skin.pulseFrequency * PI * 2.0) * skin.pulseDepth).toFloat()
    drawCircle(color.copy(alpha = 0.05f), 20.2.dp.toPx() * pulse, center)
    drawCircle(color.copy(alpha = 0.14f), 13.dp.toPx() * pulse, center)
    drawCircle(color, 7.dp.toPx() * pulse, center)
    drawCircle(Color.White.copy(alpha = 0.82f), 7.dp.toPx() * pulse, center, style = Stroke(width = 1.6.dp.toPx()))
    if (controller.phase != GamePhase.Choosing) return
    val remaining = controller.choiceRemaining().toFloat()
    drawArc(
        color = if (remaining < 0.28f) skin.palette.danger else skin.palette.primary,
        startAngle = -90f,
        sweepAngle = 360f * remaining,
        useCenter = false,
        topLeft = Offset(center.x - 26f, center.y - 26f),
        size = Size(52f, 52f),
        style = Stroke(width = 4f, cap = StrokeCap.Round)
    )
}

private fun androidx.compose.ui.graphics.drawscope.DrawScope.drawFeedback(controller: GameController, skin: GameSkin) {
    val feedback = controller.feedback ?: return
    val progress = controller.feedbackProgress()?.toFloat() ?: return
    val color = if (feedback.kind == FeedbackKind.Gem) skin.palette.safe else skin.palette.danger
    val point = if (feedback.kind == FeedbackKind.Gem) controller.round.gem.center else controller.round.hazard.center
    val center = point.toOffset(size.width, size.height)
    drawCircle(color.copy(alpha = (1f - progress) * 0.55f), 18f + 34f * progress, center, style = Stroke(width = 3f))
}

private fun screenPath(path: FuturePath, width: Float, height: Float): Path = Path().apply {
    val start = path.start.toOffset(width, height)
    val control = path.control.toOffset(width, height)
    val end = path.end.toOffset(width, height)
    moveTo(start.x, start.y)
    quadraticBezierTo(control.x, control.y, end.x, end.y)
}

private fun GamePoint.toOffset(width: Float, height: Float): Offset = Offset(
    x = width * x.toFloat(),
    y = height * (1f - y.toFloat())
)
