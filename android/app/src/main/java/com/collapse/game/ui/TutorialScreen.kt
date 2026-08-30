package com.collapse.game.ui

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
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.collapse.game.domain.TimelineBranch

private data class TutorialItem(val title: String, val detail: String, val cue: String)

private val tutorialItems = listOf(
    TutorialItem("Nhìn 2 tương lai", "Hai đường cho biết trước kết quả. Tìm nhánh tránh vùng đỏ.", "◉"),
    TutorialItem("Chạm để đổi nhánh", "Mỗi lần chạm đổi lựa chọn. Không cần vuốt hay giữ.", "☝"),
    TutorialItem("Chốt lựa chọn", "Hết thời gian, nhánh đã chọn thành hiện thực. Nhánh còn lại vỡ.", "✓")
)

@Composable
fun TutorialScreen(
    isReplay: Boolean,
    onClose: () -> Unit,
    onFinished: () -> Unit
) {
    var step by remember { mutableIntStateOf(0) }
    var selectedBranch by remember { mutableStateOf(TimelineBranch.Cyan) }
    val item = tutorialItems[step]

    Box(
        Modifier
            .fillMaxSize()
            .background(Brush.verticalGradient(listOf(Color(0xFF07101F), Color.Black)))
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 22.dp, vertical = 28.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            CollapseBrandMark(tint = CollapseCyan, subtitle = "CÁCH CHƠI")
            Spacer(Modifier.height(20.dp))
            TutorialBoard(
                step = step,
                selectedBranch = selectedBranch,
                onTap = {
                    if (step == 1) selectedBranch = selectedBranch.other
                }
            )
            Spacer(Modifier.height(20.dp))
            GlassSurface(Modifier.fillMaxWidth()) {
                Column(
                    Modifier.padding(20.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Text(item.cue, color = CollapseCyan, fontSize = 34.sp)
                    Text("BƯỚC ${step + 1}", color = CollapseCyan, fontSize = 10.sp, fontWeight = FontWeight.SemiBold, letterSpacing = 2.sp)
                    Text(item.title, color = Color.White, fontSize = 24.sp, fontWeight = FontWeight.SemiBold, textAlign = TextAlign.Center)
                    Text(item.detail, color = Color.White.copy(alpha = 0.52f), fontSize = 15.sp, textAlign = TextAlign.Center)
                }
            }
            Spacer(Modifier.height(16.dp))
            StepDots(step)
            Spacer(Modifier.height(16.dp))
            Button(
                onClick = {
                    if (step == tutorialItems.lastIndex) onFinished() else step += 1
                },
                modifier = Modifier.fillMaxWidth().height(54.dp),
                colors = ButtonDefaults.buttonColors(containerColor = CollapseCyan),
                shape = RoundedCornerShape(27.dp)
            ) {
                val title = when {
                    step != tutorialItems.lastIndex -> "TIẾP"
                    isReplay -> "XONG"
                    else -> "BẮT ĐẦU"
                }
                Text(title, color = Color.Black, fontWeight = FontWeight.SemiBold)
            }
            Spacer(Modifier.height(20.dp))
        }
        TextButton(
            onClick = if (isReplay) onClose else onFinished,
            modifier = Modifier.align(Alignment.TopEnd).padding(top = 24.dp, end = 12.dp)
        ) {
            Text(if (isReplay) "Đóng" else "Bỏ qua", color = Color.White, fontSize = 14.sp)
        }
    }
}

@Composable
private fun StepDots(step: Int) {
    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        tutorialItems.indices.forEach { index ->
            Box(
                Modifier
                    .size(width = if (index == step) 24.dp else 8.dp, height = 8.dp)
                    .background(
                        if (index == step) CollapseCyan else Color.White.copy(alpha = 0.22f),
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
    Box(
        Modifier
            .fillMaxWidth()
            .height(310.dp)
            .background(Color.White.copy(alpha = 0.025f), RoundedCornerShape(28.dp))
            .border(1.dp, Color.White.copy(alpha = 0.09f), RoundedCornerShape(28.dp))
            .pointerInput(step) { detectTapGestures { onTap() } }
    ) {
        Canvas(Modifier.fillMaxSize().padding(14.dp)) {
            val start = Offset(size.width * 0.14f, size.height * 0.52f)
            val end = Offset(size.width * 0.86f, size.height * 0.52f)
            val cyan = tutorialPath(start, Offset(size.width * 0.50f, size.height * 0.20f), end)
            val violet = tutorialPath(start, Offset(size.width * 0.50f, size.height * 0.80f), end)
            drawCircle(Color.White.copy(alpha = 0.025f), radius = size.minDimension * 0.46f, center = center)
            drawCircle(CollapseCyan.copy(alpha = 0.20f), radius = size.minDimension * 0.46f, center = center, style = Stroke(width = 1.5.dp.toPx()))
            drawTutorialHazard(Offset(size.width * 0.61f, size.height * 0.68f))
            drawTutorialPaths(step, selectedBranch, cyan, violet, start, end)
            drawCircle(if (selectedBranch == TimelineBranch.Cyan) CollapseCyan else Color(0xFFB44CFF), 8.dp.toPx(), start)
            drawCircle(Color(0xFF48EE75), 9.dp.toPx(), end)
        }
        if (step == 1) {
            Text(
                "☝",
                modifier = Modifier
                    .align(Alignment.Center)
                    .background(Color.White.copy(alpha = 0.10f), RoundedCornerShape(99.dp))
                    .padding(18.dp),
                color = Color.White,
                fontSize = 38.sp
            )
        }
    }
}

private fun androidx.compose.ui.graphics.drawscope.DrawScope.drawTutorialPaths(
    step: Int,
    selected: TimelineBranch,
    cyan: Path,
    violet: Path,
    start: Offset,
    end: Offset
) {
    val selectedCyan = selected == TimelineBranch.Cyan
    if (step == 2) {
        val chosen = if (selectedCyan) cyan else violet
        drawPath(chosen, if (selectedCyan) CollapseCyan else Color(0xFFB44CFF), style = Stroke(3.dp.toPx(), cap = StrokeCap.Round))
        drawTutorialShards(selectedCyan, start, end)
        return
    }
    val dash = PathEffect.dashPathEffect(floatArrayOf(16f, 12f))
    drawPath(cyan, CollapseCyan.copy(alpha = if (selectedCyan) 0.96f else 0.30f), style = Stroke(if (selectedCyan) 3.dp.toPx() else 1.5.dp.toPx(), cap = StrokeCap.Round, pathEffect = dash))
    drawPath(violet, Color(0xFFB44CFF).copy(alpha = if (selectedCyan) 0.30f else 0.96f), style = Stroke(if (selectedCyan) 1.5.dp.toPx() else 3.dp.toPx(), cap = StrokeCap.Round, pathEffect = dash))
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

private fun androidx.compose.ui.graphics.drawscope.DrawScope.drawTutorialHazard(center: Offset) {
    drawCircle(Color.Red.copy(alpha = 0.09f), 24.dp.toPx(), center)
    drawCircle(Color.Red, 12.dp.toPx(), center, style = Stroke(width = 2.dp.toPx()))
}

private fun tutorialPath(start: Offset, control: Offset, end: Offset): Path = Path().apply {
    moveTo(start.x, start.y)
    quadraticBezierTo(control.x, control.y, end.x, end.y)
}
