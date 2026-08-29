package com.collapse.game

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.isActive
import kotlin.math.max
import kotlin.math.min
import kotlin.random.Random

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            MaterialTheme(colorScheme = darkColorScheme()) {
                Surface(modifier = Modifier.fillMaxSize(), color = Background) {
                    CollapseGame()
                }
            }
        }
    }
}

private val Background = Color(0xFF050814)
private val Cyan = Color(0xFF6FEAFF)
private val Violet = Color(0xFFC98CFF)
private val Safe = Color(0xFF66FFB7)
private val Danger = Color(0xFFFF5368)

enum class Branch {
    Cyan,
    Violet;

    fun other(): Branch = if (this == Cyan) Violet else Cyan
}

enum class Phase {
    Choosing,
    Traveling,
    Dead
}

data class Point(val x: Float, val y: Float)

data class FuturePath(
    val start: Point,
    val control: Point,
    val end: Point
) {
    fun pointAt(rawT: Float): Point {
        val t = rawT.coerceIn(0f, 1f)
        val inverse = 1f - t
        return Point(
            x = inverse * inverse * start.x + 2f * inverse * t * control.x + t * t * end.x,
            y = inverse * inverse * start.y + 2f * inverse * t * control.y + t * t * end.y
        )
    }
}

data class Hazard(
    val center: Point,
    val radius: Float,
    val pathProgress: Float
)

data class RoundLayout(
    val cyanPath: FuturePath,
    val violetPath: FuturePath,
    val hazard: Hazard,
    val dangerBranch: Branch
) {
    fun path(branch: Branch): FuturePath = if (branch == Branch.Cyan) cyanPath else violetPath
}

private class GameController {
    var score by mutableIntStateOf(0)
        private set
    var phase by mutableStateOf(Phase.Choosing)
        private set
    var selectedBranch by mutableStateOf(Branch.Cyan)
        private set
    var round by mutableStateOf(makeRound(0))
        private set
    var travelProgress by mutableFloatStateOf(0f)
        private set
    var nowNanos by mutableStateOf(0L)
        private set

    private var roundIndex = 0
    private var decisionStartNanos = 0L
    private var travelStartNanos = 0L

    val choiceDurationSeconds: Float
        get() = max(0.72f, 1.45f - score * 0.045f)

    val travelDurationSeconds: Float
        get() = max(0.62f, 0.90f - score * 0.012f)

    fun tick(frameNanos: Long) {
        nowNanos = frameNanos
        if (decisionStartNanos == 0L) {
            decisionStartNanos = frameNanos
        }

        when (phase) {
            Phase.Choosing -> {
                if (elapsedSeconds(decisionStartNanos, frameNanos) >= choiceDurationSeconds) {
                    phase = Phase.Traveling
                    travelStartNanos = frameNanos
                    travelProgress = 0f
                }
            }
            Phase.Traveling -> {
                travelProgress = (
                    elapsedSeconds(travelStartNanos, frameNanos) / travelDurationSeconds
                ).coerceIn(0f, 1f)

                if (
                    selectedBranch == round.dangerBranch &&
                    travelProgress >= round.hazard.pathProgress - 0.035f
                ) {
                    phase = Phase.Dead
                    return
                }

                if (travelProgress >= 1f) {
                    score += 1
                    roundIndex += 1
                    round = makeRound(roundIndex)
                    selectedBranch = if (score % 2 == 0) Branch.Cyan else Branch.Violet
                    travelProgress = 0f
                    phase = Phase.Choosing
                    decisionStartNanos = frameNanos
                }
            }
            Phase.Dead -> Unit
        }
    }

    fun tap() {
        when (phase) {
            Phase.Choosing -> selectedBranch = selectedBranch.other()
            Phase.Dead -> restart()
            Phase.Traveling -> Unit
        }
    }

    fun choiceRemaining(): Float {
        if (phase != Phase.Choosing || decisionStartNanos == 0L) return 0f
        val elapsed = elapsedSeconds(decisionStartNanos, nowNanos)
        return (1f - elapsed / choiceDurationSeconds).coerceIn(0f, 1f)
    }

    private fun restart() {
        score = 0
        roundIndex = 0
        round = makeRound(0)
        selectedBranch = Branch.Cyan
        travelProgress = 0f
        phase = Phase.Choosing
        decisionStartNanos = nowNanos
    }

    private fun elapsedSeconds(start: Long, end: Long): Float = (end - start) / 1_000_000_000f
}

@Composable
private fun CollapseGame() {
    val controller = androidx.compose.runtime.remember { GameController() }

    LaunchedEffect(Unit) {
        while (isActive) {
            withFrameNanos { frame -> controller.tick(frame) }
        }
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Background)
    ) {
        GameCanvas(
            controller = controller,
            modifier = Modifier
                .fillMaxSize()
                .pointerInput(controller.phase) {
                    detectTapGestures { controller.tap() }
                }
        )

        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = 20.dp, vertical = 22.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.Top
            ) {
                Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    Text(
                        text = "COLLAPSE",
                        color = Color.White.copy(alpha = 0.78f),
                        fontSize = 13.sp,
                        fontWeight = FontWeight.Medium,
                        letterSpacing = 4.sp
                    )
                    Text(
                        text = "DỰ BÁO ${"%.1f".format(controller.choiceDurationSeconds)}s",
                        color = Cyan,
                        fontSize = 11.sp,
                        letterSpacing = 1.5.sp
                    )
                }

                Column(horizontalAlignment = Alignment.End) {
                    Text(
                        text = controller.score.toString(),
                        color = Color.White,
                        fontSize = 38.sp,
                        fontWeight = FontWeight.SemiBold
                    )
                    Text(
                        text = "ĐIỂM",
                        color = Color.White.copy(alpha = 0.46f),
                        fontSize = 10.sp,
                        letterSpacing = 2.sp
                    )
                }
            }

            Spacer(modifier = Modifier.weight(1f))

            Text(
                text = if (controller.phase == Phase.Dead) {
                    "MẤT DÒNG THỜI GIAN · CHẠM ĐỂ CHƠI LẠI"
                } else {
                    "CHẠM ĐỂ ĐỔI TƯƠNG LAI"
                },
                modifier = Modifier
                    .align(Alignment.CenterHorizontally)
                    .background(
                        Color.Black.copy(alpha = 0.38f),
                        RoundedCornerShape(999.dp)
                    )
                    .padding(horizontal = 16.dp, vertical = 10.dp),
                color = if (controller.phase == Phase.Dead) Danger else Color.White.copy(alpha = 0.78f),
                fontSize = 11.sp,
                fontWeight = FontWeight.SemiBold,
                letterSpacing = 1.2.sp
            )
        }
    }
}

@Composable
private fun GameCanvas(controller: GameController, modifier: Modifier = Modifier) {
    Canvas(modifier = modifier) {
        val round = controller.round
        val cyanPath = screenPath(round.cyanPath, size.width, size.height)
        val violetPath = screenPath(round.violetPath, size.width, size.height)
        val dash = PathEffect.dashPathEffect(floatArrayOf(14f, 12f))

        drawPath(
            path = cyanPath,
            color = Cyan.copy(alpha = if (controller.selectedBranch == Branch.Cyan) 0.18f else 0.05f),
            style = Stroke(width = if (controller.selectedBranch == Branch.Cyan) 12f else 6f, cap = StrokeCap.Round)
        )
        drawPath(
            path = violetPath,
            color = Violet.copy(alpha = if (controller.selectedBranch == Branch.Violet) 0.18f else 0.05f),
            style = Stroke(width = if (controller.selectedBranch == Branch.Violet) 12f else 6f, cap = StrokeCap.Round)
        )
        drawPath(
            path = cyanPath,
            color = Cyan.copy(alpha = if (controller.selectedBranch == Branch.Cyan) 0.95f else 0.32f),
            style = Stroke(
                width = if (controller.selectedBranch == Branch.Cyan) 4f else 2f,
                cap = StrokeCap.Round,
                pathEffect = if (controller.phase == Phase.Choosing) dash else null
            )
        )
        drawPath(
            path = violetPath,
            color = Violet.copy(alpha = if (controller.selectedBranch == Branch.Violet) 0.95f else 0.32f),
            style = Stroke(
                width = if (controller.selectedBranch == Branch.Violet) 4f else 2f,
                cap = StrokeCap.Round,
                pathEffect = if (controller.phase == Phase.Choosing) dash else null
            )
        )

        val hazard = toOffset(round.hazard.center, size.width, size.height)
        val hazardRadius = min(size.width, size.height) * round.hazard.radius
        drawCircle(Danger.copy(alpha = 0.10f), radius = hazardRadius * 2.2f, center = hazard)
        drawCircle(Danger.copy(alpha = 0.18f), radius = hazardRadius, center = hazard)
        drawCircle(Danger, radius = hazardRadius, center = hazard, style = Stroke(width = 3f))
        drawCircle(Color.White.copy(alpha = 0.24f), radius = hazardRadius * 0.52f, center = hazard, style = Stroke(width = 1.5f))

        val portal = toOffset(round.cyanPath.end, size.width, size.height)
        drawCircle(Safe.copy(alpha = 0.18f), radius = 22f, center = portal)
        drawCircle(Safe, radius = 10f, center = portal, style = Stroke(width = 3f))

        if (controller.phase == Phase.Choosing) {
            listOf(0.27f, 0.50f, 0.74f).forEachIndexed { index, progress ->
                val cyanGhost = toOffset(round.cyanPath.pointAt(progress), size.width, size.height)
                val violetGhost = toOffset(round.violetPath.pointAt(progress), size.width, size.height)
                val radius = 5f + index
                drawCircle(Cyan.copy(alpha = 0.32f + index * 0.1f), radius = radius, center = cyanGhost)
                drawCircle(Violet.copy(alpha = 0.32f + index * 0.1f), radius = radius, center = violetGhost)
            }
        }

        val playerPoint = when (controller.phase) {
            Phase.Choosing -> round.cyanPath.start
            Phase.Traveling, Phase.Dead -> round.path(controller.selectedBranch).pointAt(controller.travelProgress)
        }
        val player = toOffset(playerPoint, size.width, size.height)
        val playerColor = if (controller.selectedBranch == Branch.Cyan) Cyan else Violet
        drawCircle(playerColor.copy(alpha = 0.14f), radius = 20f, center = player)
        drawCircle(playerColor, radius = 10f, center = player)
        drawCircle(Color.White.copy(alpha = 0.90f), radius = 4f, center = player)

        if (controller.phase == Phase.Choosing) {
            val remaining = controller.choiceRemaining()
            drawArc(
                color = if (remaining < 0.28f) Danger else Cyan,
                startAngle = -90f,
                sweepAngle = 360f * remaining,
                useCenter = false,
                topLeft = Offset(player.x - 26f, player.y - 26f),
                size = androidx.compose.ui.geometry.Size(52f, 52f),
                style = Stroke(width = 4f, cap = StrokeCap.Round)
            )
        }
    }
}

private fun screenPath(path: FuturePath, width: Float, height: Float): Path = Path().apply {
    val start = toOffset(path.start, width, height)
    val control = toOffset(path.control, width, height)
    val end = toOffset(path.end, width, height)
    moveTo(start.x, start.y)
    quadraticBezierTo(control.x, control.y, end.x, end.y)
}

private fun toOffset(point: Point, width: Float, height: Float): Offset = Offset(
    x = width * point.x,
    y = height * point.y
)

private fun makeRound(index: Int): RoundLayout {
    val random = Random(0xC011A953.toInt() xor (index * 0x45D9F3B))
    val startY = 0.48f + (random.nextFloat() - 0.5f) * 0.10f
    val endY = 0.48f + (random.nextFloat() - 0.5f) * 0.16f
    val spread = 0.22f + random.nextFloat() * 0.06f
    val start = Point(0.12f, startY)
    val end = Point(0.88f, endY)
    val middle = (startY + endY) / 2f
    val cyanPath = FuturePath(
        start = start,
        control = Point(0.50f, (middle - spread).coerceIn(0.18f, 0.82f)),
        end = end
    )
    val violetPath = FuturePath(
        start = start,
        control = Point(0.50f, (middle + spread).coerceIn(0.18f, 0.82f)),
        end = end
    )
    val dangerBranch = if (random.nextBoolean()) Branch.Cyan else Branch.Violet
    val hazardProgress = 0.54f + random.nextFloat() * 0.16f
    val dangerousPath = if (dangerBranch == Branch.Cyan) cyanPath else violetPath
    return RoundLayout(
        cyanPath = cyanPath,
        violetPath = violetPath,
        hazard = Hazard(
            center = dangerousPath.pointAt(hazardProgress),
            radius = 0.055f,
            pathProgress = hazardProgress
        ),
        dangerBranch = dangerBranch
    )
}
