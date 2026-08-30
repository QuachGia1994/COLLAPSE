package com.collapse.game.ui

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
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
import com.collapse.game.R
import com.collapse.game.domain.TimelineBranch

private data class TutorialItem(val title: String, val detail: String, val cue: String)

@Composable
fun TutorialScreen(
    isReplay: Boolean,
    onClose: () -> Unit,
    onFinished: () -> Unit
) {
    var step by remember { mutableIntStateOf(0) }
    var selectedBranch by remember { mutableStateOf(TimelineBranch.Cyan) }
    val items = listOf(
        TutorialItem(stringResource(R.string.tutorial_step1_title), stringResource(R.string.tutorial_step1_detail), "◉"),
        TutorialItem(stringResource(R.string.tutorial_step2_title), stringResource(R.string.tutorial_step2_detail), "☝"),
        TutorialItem(stringResource(R.string.tutorial_step3_title), stringResource(R.string.tutorial_step3_detail), "✓")
    )
    val item = items[step]

    BoxWithConstraints(
        Modifier
            .fillMaxSize()
            .background(Brush.verticalGradient(listOf(Color(0xFF07101F), Color.Black)))
    ) {
        val compactHeight = maxHeight < 760.dp
        val gap = if (compactHeight) 12.dp else 18.dp

        Column(
            modifier = Modifier
                .fillMaxSize()
                .statusBarsPadding()
                .navigationBarsPadding()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 20.dp, vertical = 18.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            TutorialHeader(isReplay, onClose, onFinished)
            Spacer(Modifier.height(gap))
            TutorialBoard(
                step = step,
                selectedBranch = selectedBranch,
                onTap = {
                    if (step == 1) selectedBranch = selectedBranch.other
                }
            )
            Spacer(Modifier.height(gap))
            GlassSurface(Modifier.fillMaxWidth(), radius = 24.dp) {
                Column(
                    Modifier.padding(if (compactHeight) 14.dp else 18.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(if (compactHeight) 5.dp else 9.dp)
                ) {
                    Text(item.cue, color = CollapseCyan, fontSize = if (compactHeight) 26.sp else 32.sp)
                    Text("${stringResource(R.string.tutorial_step)} ${step + 1}", color = CollapseCyan, fontSize = 10.sp, fontWeight = FontWeight.SemiBold, letterSpacing = 2.sp)
                    Text(item.title, color = Color.White, fontSize = if (compactHeight) 21.sp else 24.sp, fontWeight = FontWeight.SemiBold, textAlign = TextAlign.Center)
                    Text(
                        item.detail,
                        color = Color.White.copy(alpha = 0.52f),
                        fontSize = if (compactHeight) 13.sp else 15.sp,
                        textAlign = TextAlign.Center,
                        modifier = Modifier.widthIn(max = 330.dp)
                    )
                }
            }
            Spacer(Modifier.height(if (compactHeight) 10.dp else 16.dp))
            StepDots(step)
            Spacer(Modifier.height(if (compactHeight) 10.dp else 16.dp))
            Button(
                onClick = {
                    if (step == items.lastIndex) onFinished() else step += 1
                },
                modifier = Modifier.fillMaxWidth().height(if (compactHeight) 50.dp else 54.dp),
                colors = ButtonDefaults.buttonColors(containerColor = CollapseCyan),
                shape = RoundedCornerShape(27.dp)
            ) {
                val title = when {
                    step != items.lastIndex -> stringResource(R.string.tutorial_next)
                    isReplay -> stringResource(R.string.tutorial_done)
                    else -> stringResource(R.string.tutorial_start)
                }
                Text(title, color = Color.Black, fontWeight = FontWeight.SemiBold)
            }
            Spacer(Modifier.height(12.dp))
        }
    }
}

@Composable
private fun TutorialHeader(
    isReplay: Boolean,
    onClose: () -> Unit,
    onFinished: () -> Unit
) {
    Row(
        Modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        CollapseBrandMark(
            tint = CollapseCyan,
            subtitle = stringResource(R.string.tutorial_subtitle),
            compact = true,
            modifier = Modifier.weight(1f)
        )
        TextButton(onClick = if (isReplay) onClose else onFinished) {
            Text(if (isReplay) stringResource(R.string.tutorial_close) else stringResource(R.string.tutorial_skip), color = Color.White, fontSize = 14.sp)
        }
    }
}

@Composable
private fun StepDots(step: Int) {
    Row(horizontalArrangement = Arrangement.spacedBy(7.dp)) {
        repeat(3) { index ->
            Box(
                Modifier
                    .size(width = if (index == step) 26.dp else 7.dp, height = 7.dp)
                    .background(
                        if (index == step) CollapseCyan else Color.White.copy(alpha = 0.18f),
                        RoundedCornerShape(99.dp)
                    )
            )
        }
    }
}

@Composable
private fun TutorialBoard(
    step: Int,
    selectedBranch: TimelineBranch,
    onTap: () -> Unit
) {
    val cyanAlpha by animateFloatAsState(
        targetValue = if (selectedBranch == TimelineBranch.Cyan) 0.96f else 0.30f,
        animationSpec = tween(durationMillis = 220),
        label = "tutorialCyanAlpha"
    )
    val violetAlpha by animateFloatAsState(
        targetValue = if (selectedBranch == TimelineBranch.Cyan) 0.30f else 0.96f,
        animationSpec = tween(durationMillis = 220),
        label = "tutorialVioletAlpha"
    )
    Box(
        Modifier
            .fillMaxWidth()
            .widthIn(max = 390.dp)
            .aspectRatio(1.08f)
            .background(Color.White.copy(alpha = 0.025f), RoundedCornerShape(30.dp))
            .border(1.dp, Color.White.copy(alpha = 0.12f), RoundedCornerShape(30.dp))
            .pointerInput(step) { detectTapGestures { onTap() } }
    ) {
        Canvas(Modifier.fillMaxSize().padding(12.dp)) {
            val start = Offset(size.width * 0.14f, size.height * 0.52f)
            val end = Offset(size.width * 0.86f, size.height * 0.52f)
            val cyan = tutorialPath(start, Offset(size.width * 0.50f, size.height * 0.20f), end)
            val violet = tutorialPath(start, Offset(size.width * 0.50f, size.height * 0.80f), end)
            drawCircle(Color.White.copy(alpha = 0.025f), radius = size.minDimension * 0.46f, center = center)
            drawCircle(CollapseCyan.copy(alpha = 0.20f), radius = size.minDimension * 0.46f, center = center, style = Stroke(width = 1.5.dp.toPx()))
            drawTutorialHazard(Offset(size.width * 0.61f, size.height * 0.68f), size)
            drawTutorialPaths(step, selectedBranch, cyan, violet, cyanAlpha, violetAlpha)
            drawCircle(if (selectedBranch == TimelineBranch.Cyan) CollapseCyan else Color(0xFFB44CFF), 8.dp.toPx(), start)
            drawCircle(Color(0xFF48EE75), 9.dp.toPx(), end)
        }
        if (step == 1) {
            Text(
                "☝",
                modifier = Modifier
                    .align(Alignment.Center)
                    .background(Color.White.copy(alpha = 0.08f), RoundedCornerShape(99.dp))
                    .padding(18.dp),
                color = Color.White.copy(alpha = 0.88f),
                fontSize = 42.sp
            )
        }
    }
}

private fun androidx.compose.ui.graphics.drawscope.DrawScope.drawTutorialPaths(
    step: Int,
    selected: TimelineBranch,
    cyan: Path,
    violet: Path,
    cyanAlpha: Float,
    violetAlpha: Float
) {
    val selectedCyan = selected == TimelineBranch.Cyan
    if (step == 2) {
        val chosen = if (selectedCyan) cyan else violet
        drawPath(chosen, if (selectedCyan) CollapseCyan else Color(0xFFB44CFF), style = Stroke(3.dp.toPx(), cap = StrokeCap.Round))
        drawTutorialShards(selectedCyan, start = Offset(size.width * 0.14f, size.height * 0.52f), end = Offset(size.width * 0.86f, size.height * 0.52f))
        return
    }
    val dash = PathEffect.dashPathEffect(floatArrayOf(9.dp.toPx(), 8.dp.toPx()))
    drawPath(cyan, CollapseCyan.copy(alpha = cyanAlpha), style = Stroke(if (selectedCyan) 3.dp.toPx() else 1.5.dp.toPx(), cap = StrokeCap.Round, pathEffect = dash))
    drawPath(violet, Color(0xFFB44CFF).copy(alpha = violetAlpha), style = Stroke(if (selectedCyan) 1.5.dp.toPx() else 3.dp.toPx(), cap = StrokeCap.Round, pathEffect = dash))
}

private fun androidx.compose.ui.graphics.drawscope.DrawScope.drawTutorialShards(
    selectedCyan: Boolean,
    start: Offset,
    end: Offset
) {
    val control = Offset(size.width * 0.50f, size.height * if (selectedCyan) 0.80f else 0.20f)
    val color = if (selectedCyan) Color(0xFFB44CFF) else CollapseCyan
    for (index in 0 until 12) {
        val progress = (index + 2) / 15f
        val center = quadraticPoint(start, control, end, progress)
        drawRoundRect(
            color = color.copy(alpha = 0.68f),
            topLeft = Offset(center.x - 3.dp.toPx(), center.y - 1.dp.toPx()),
            size = androidx.compose.ui.geometry.Size(6.dp.toPx(), 2.dp.toPx()),
            cornerRadius = androidx.compose.ui.geometry.CornerRadius(1.dp.toPx())
        )
    }
}

private fun quadraticPoint(start: Offset, control: Offset, end: Offset, progress: Float): Offset {
    val inverse = 1f - progress
    return Offset(
        x = inverse * inverse * start.x + 2f * inverse * progress * control.x + progress * progress * end.x,
        y = inverse * inverse * start.y + 2f * inverse * progress * control.y + progress * progress * end.y
    )
}

private fun androidx.compose.ui.graphics.drawscope.DrawScope.drawTutorialHazard(center: Offset, size: Size) {
    val minDimension = minOf(size.width, size.height)
    drawCircle(Color.Red.copy(alpha = 0.10f), minDimension * 0.075f, center)
    drawCircle(Color.Red, minDimension * 0.038f, center, style = Stroke(width = 2.2.dp.toPx()))
}

private fun tutorialPath(start: Offset, control: Offset, end: Offset): Path = Path().apply {
    moveTo(start.x, start.y)
    quadraticBezierTo(control.x, control.y, end.x, end.y)
}
