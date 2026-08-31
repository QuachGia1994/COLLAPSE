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
import androidx.compose.ui.graphics.PathEffect
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
                letterSpacing = if (compact) 3.sp else 6.sp,
                maxLines = 1
            )
            if (subtitle.isNotEmpty()) {
                Text(
                    text = subtitle,
                    color = Color.White.copy(alpha = 0.48f),
                    fontSize = 10.sp,
                    fontWeight = FontWeight.Medium,
                    letterSpacing = if (compact) 1.5.sp else 2.5.sp,
                    maxLines = 1
                )
            }
        }
    }
}

// Canonical COLLAPSE icon palette sampled from the AppIcon artwork; every
// in-app logo surface draws the same composition as the app-screen icon.
private val IconRingCyan = Color(0xFF70EEFF)
private val IconRingMagenta = Color(0xFFF773FF)
private val IconDashCyan = Color(0xFF28DAFF)
private val IconDashMagenta = Color(0xFFD450FF)
private val IconPlanetLight = Color(0xFF9AB2CE)
private val IconPlanetMid = Color(0xFF86A0E7)
private val IconPlanetDeep = Color(0xFF3A468E)
private val IconPlanetGlow = Color(0xFF963CBD)
private val IconShard = Color(0xFF965FFF)

@Composable
fun CollapseLogoSymbol(tint: Color, modifier: Modifier = Modifier) {
    Canvas(modifier) {
        val minDimension = minOf(size.width, size.height)
        val center = Offset(size.width / 2f, size.height / 2f)
        val ringRadius = minDimension * 0.375f
        val planetRadius = ringRadius * 0.61f

        val glowCenter = Offset(center.x, center.y - minDimension * 0.05f)
        drawCircle(
            brush = Brush.radialGradient(
                colors = listOf(IconPlanetGlow.copy(alpha = 0.55f), IconPlanetGlow.copy(alpha = 0f)),
                center = glowCenter,
                radius = ringRadius * 1.05f
            ),
            radius = ringRadius * 1.05f,
            center = glowCenter
        )
        drawCircle(
            brush = Brush.radialGradient(
                colors = listOf(IconPlanetLight, IconPlanetMid, IconPlanetDeep),
                center = Offset(center.x - planetRadius * 0.35f, center.y - planetRadius * 0.45f),
                radius = planetRadius * 1.55f
            ),
            radius = planetRadius,
            center = center
        )
        drawCircle(
            brush = Brush.sweepGradient(listOf(IconRingMagenta, IconRingCyan, IconRingMagenta), center),
            radius = ringRadius,
            center = center,
            style = Stroke(width = (minDimension * 0.012f).coerceAtLeast(1.dp.toPx()), cap = StrokeCap.Round)
        )

        val start = Offset(center.x - ringRadius, center.y + minDimension * 0.027f)
        val end = Offset(center.x + ringRadius, center.y - minDimension * 0.024f)
        val dash = PathEffect.dashPathEffect(floatArrayOf(minDimension * 0.021f, minDimension * 0.013f))
        val upper = Path().apply {
            moveTo(start.x, start.y)
            quadraticBezierTo(center.x, center.y - minDimension * 0.18f, end.x, end.y)
        }
        drawPath(upper, IconDashCyan, style = Stroke(minDimension * 0.014f, cap = StrokeCap.Round, pathEffect = dash))
        val lower = Path().apply {
            moveTo(start.x, start.y)
            quadraticBezierTo(center.x, center.y + minDimension * 0.18f, end.x, end.y)
        }
        drawPath(lower, IconDashMagenta, style = Stroke(minDimension * 0.014f, cap = StrokeCap.Round, pathEffect = dash))

        val nodeRadius = minDimension * 0.023f
        drawCircle(IconRingCyan, nodeRadius, start)
        drawCircle(IconRingMagenta, nodeRadius, end)

        val triangleWidth = minDimension * 0.021f
        val triangleHeight = minDimension * 0.019f
        val spacingX = minDimension * 0.044f
        val rows = listOf(0.195f to 0.700f, 0.275f to 0.712f, 0.355f to 0.690f)
        for ((rowY, rowX) in rows) {
            for (column in 0..4) {
                val originX = minDimension * rowX + column * spacingX
                val originY = minDimension * rowY
                val triangle = Path().apply {
                    moveTo(originX, originY)
                    lineTo(originX + triangleWidth, originY + triangleHeight / 2f)
                    lineTo(originX, originY + triangleHeight)
                    close()
                }
                drawPath(triangle, IconShard, style = Stroke((minDimension * 0.003f).coerceAtLeast(0.8f)))
            }
        }
    }
}

@Composable
fun MetricBlock(title: String, value: String, modifier: Modifier = Modifier, valueSize: Int = 17) {
    Column(modifier, horizontalAlignment = Alignment.CenterHorizontally) {
        Text(value, color = Color.White, fontSize = valueSize.sp, fontWeight = FontWeight.SemiBold)
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
    borderAlpha: Float = 0.12f,
    content: @Composable () -> Unit
) {
    Surface(
        modifier = modifier.border(1.dp, Color.White.copy(alpha = borderAlpha), RoundedCornerShape(radius)),
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
