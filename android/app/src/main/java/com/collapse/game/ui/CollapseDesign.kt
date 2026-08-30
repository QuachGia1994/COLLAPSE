package com.collapse.game.ui

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

val CollapseBackground = Color(0xFF03050C)
val CollapseSurface = Color(0xFF15171D)
val CollapseCyan = Color(0xFF36CBF2)
val CollapseYellow = Color(0xFFFFD72E)

@Composable
fun CollapseTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = darkColorScheme(
            background = CollapseBackground,
            surface = CollapseSurface,
            primary = CollapseCyan,
            secondary = Color(0xFFB44CFF)
        ),
        content = content
    )
}

fun Modifier.glassPanel(radius: Dp = 28.dp): Modifier =
    background(Color.White.copy(alpha = 0.085f), RoundedCornerShape(radius))
        .border(1.dp, Color.White.copy(alpha = 0.11f), RoundedCornerShape(radius))

@Composable
fun CollapseBrandMark(
    tint: Color,
    subtitle: String = "CHỌN TƯƠNG LAI",
    compact: Boolean = false,
    modifier: Modifier = Modifier
) {
    Row(modifier = modifier, verticalAlignment = Alignment.CenterVertically) {
        CollapseLogoSymbol(tint, Modifier.size(if (compact) 38.dp else 54.dp))
        Spacer(Modifier.size(if (compact) 10.dp else 14.dp))
        Column {
            Text(
                text = "COLLAPSE",
                color = Color.White,
                fontSize = if (compact) 18.sp else 30.sp,
                fontWeight = if (compact) FontWeight.Medium else FontWeight.Light,
                letterSpacing = if (compact) 3.sp else 6.sp
            )
            if (subtitle.isNotEmpty()) {
                Text(
                    text = subtitle,
                    color = Color.White.copy(alpha = 0.48f),
                    fontSize = 10.sp,
                    fontWeight = FontWeight.Medium,
                    letterSpacing = if (compact) 1.5.sp else 2.5.sp
                )
            }
        }
    }
}

@Composable
fun CollapseLogoSymbol(tint: Color, modifier: Modifier = Modifier) {
    Canvas(modifier) {
        val inset = size.minDimension * 0.08f
        val center = Offset(size.width / 2f, size.height / 2f)
        val radius = (size.minDimension - inset * 2f) / 2f
        drawCircle(tint.copy(alpha = 0.72f), radius, center, style = Stroke(width = 1.6.dp.toPx()))
        drawFutureCurve(tint, upper = true)
        drawFutureCurve(Color(0xFFB44CFF), upper = false)
        drawLogoNodes(tint)
    }
}

private fun androidx.compose.ui.graphics.drawscope.DrawScope.drawFutureCurve(color: Color, upper: Boolean) {
    val path = Path()
    val startY = if (upper) 0.62f else 0.42f
    val endY = if (upper) 0.38f else 0.66f
    val controlY = if (upper) 0.22f else 0.78f
    path.moveTo(size.width * 0.20f, size.height * startY)
    path.quadraticBezierTo(size.width * 0.50f, size.height * controlY, size.width * 0.80f, size.height * endY)
    drawPath(path, color, style = Stroke(width = 2.4.dp.toPx(), cap = StrokeCap.Round))
}

private fun androidx.compose.ui.graphics.drawscope.DrawScope.drawLogoNodes(tint: Color) {
    drawCircle(tint, 4.5.dp.toPx(), Offset(size.width * 0.18f, size.height * 0.53f))
    drawCircle(Color(0xFF4DFF8D), 4.5.dp.toPx(), Offset(size.width * 0.82f, size.height * 0.38f))
    drawCircle(
        Color(0xFFFF4C57),
        6.dp.toPx(),
        Offset(size.width * 0.75f, size.height * 0.67f),
        style = Stroke(width = 2.dp.toPx())
    )
}

@Composable
fun MetricBlock(title: String, value: String, modifier: Modifier = Modifier) {
    Column(modifier, horizontalAlignment = Alignment.CenterHorizontally) {
        Text(value, color = Color.White, fontSize = 17.sp, fontWeight = FontWeight.SemiBold)
        Text(
            title,
            color = Color.White.copy(alpha = 0.48f),
            fontSize = 10.sp,
            letterSpacing = 1.4.sp,
            textAlign = TextAlign.Center
        )
    }
}

@Composable
fun GlassSurface(
    modifier: Modifier = Modifier,
    radius: Dp = 28.dp,
    content: @Composable () -> Unit
) {
    Surface(
        modifier = modifier.border(1.dp, Color.White.copy(alpha = 0.11f), RoundedCornerShape(radius)),
        shape = RoundedCornerShape(radius),
        color = Color.White.copy(alpha = 0.075f),
        content = content
    )
}

@Composable
fun GradientBackdrop(palette: SkinPalette, modifier: Modifier = Modifier) {
    Box(
        modifier.background(
            Brush.verticalGradient(listOf(palette.backgroundTop, palette.backgroundBottom))
        )
    )
}
