package com.collapse.game.ui

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
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
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
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
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.collapse.game.services.PlayerProfile

@Composable
fun HomeScreen(
    profile: PlayerProfile,
    isPlusUnlocked: Boolean,
    onPlay: () -> Unit,
    onSkins: () -> Unit,
    onPlus: () -> Unit,
    onTutorial: () -> Unit
) {
    val skin = profile.activeSkin(isPlusUnlocked)
    Box(
        Modifier
            .fillMaxSize()
            .background(Brush.verticalGradient(listOf(skin.palette.backgroundTop, skin.palette.backgroundBottom)))
    ) {
        AmbientGlass(skin.palette)
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 20.dp, vertical = 28.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            Spacer(Modifier.height(20.dp))
            CollapseBrandMark(tint = skin.palette.primary)
            Spacer(Modifier.height(18.dp))
            HomeOrb(skin)
            Spacer(Modifier.height(18.dp))
            HomeActions(skin, onPlay, onSkins, onPlus)
            Spacer(Modifier.height(18.dp))
            HomeMetrics(profile)
            TextButton(onClick = onTutorial, modifier = Modifier.padding(top = 14.dp)) {
                Text("Xem lại hướng dẫn", color = Color.White.copy(alpha = 0.52f), fontSize = 13.sp)
            }
            Spacer(Modifier.height(24.dp))
        }
    }
}

@Composable
private fun HomeActions(
    skin: GameSkin,
    onPlay: () -> Unit,
    onSkins: () -> Unit,
    onPlus: () -> Unit
) {
    GlassSurface(modifier = Modifier.fillMaxWidth(), radius = 28.dp) {
        Column(Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
            Button(
                onClick = onPlay,
                modifier = Modifier.fillMaxWidth().height(58.dp),
                colors = ButtonDefaults.buttonColors(containerColor = skin.palette.primary),
                shape = RoundedCornerShape(28.dp)
            ) {
                Text("▶  CHƠI", color = Color.Black, fontSize = 19.sp, fontWeight = FontWeight.Medium)
            }
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                OutlinedButton(onClick = onSkins, modifier = Modifier.weight(1f), shape = RoundedCornerShape(24.dp)) {
                    Text("◉  SKIN", color = skin.palette.primary, fontSize = 16.sp)
                }
                Button(
                    onClick = onPlus,
                    modifier = Modifier.weight(1f),
                    colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF514A08)),
                    shape = RoundedCornerShape(24.dp)
                ) {
                    Text("◆  PLUS", color = CollapseYellow, fontSize = 16.sp)
                }
            }
        }
    }
}

@Composable
private fun HomeMetrics(profile: PlayerProfile) {
    GlassSurface(modifier = Modifier.fillMaxWidth(), radius = 999.dp) {
        Row(
            modifier = Modifier.fillMaxWidth().padding(horizontal = 14.dp, vertical = 12.dp),
            horizontalArrangement = Arrangement.SpaceEvenly,
            verticalAlignment = Alignment.CenterVertically
        ) {
            MetricBlock("KỶ LỤC", profile.bestScore.toString(), Modifier.weight(1f))
            MetricBlock("HÔM NAY", profile.dailyBestScore.toString(), Modifier.weight(1f))
            MetricBlock("STREAK", "🔥${profile.dailyRunStreak}", Modifier.weight(1f))
            MetricBlock("GEM", "◆${profile.gemBalance}", Modifier.weight(1f))
        }
    }
}

@Composable
private fun HomeOrb(skin: GameSkin) {
    Canvas(Modifier.size(236.dp)) {
        val center = Offset(size.width / 2f, size.height / 2f)
        val radius = size.minDimension * 0.46f
        drawCircle(Color.White.copy(alpha = 0.07f), radius, center)
        drawCircle(skin.palette.primary.copy(alpha = 0.34f), radius, center, style = Stroke(width = 2.dp.toPx()))
        drawOrbPath(skin.palette.primary, upper = true)
        drawOrbPath(skin.palette.secondary, upper = false)
        drawCircle(skin.palette.primary, 8.dp.toPx(), Offset(size.width * 0.12f, size.height * 0.52f))
        drawCircle(skin.palette.safe, 8.5.dp.toPx(), Offset(size.width * 0.88f, size.height * 0.28f))
        drawCircle(
            skin.palette.danger,
            11.dp.toPx(),
            Offset(size.width * 0.78f, size.height * 0.76f),
            style = Stroke(width = 3.dp.toPx())
        )
    }
}

private fun androidx.compose.ui.graphics.drawscope.DrawScope.drawOrbPath(color: Color, upper: Boolean) {
    val path = Path()
    val startY = if (upper) 0.66f else 0.44f
    val endY = if (upper) 0.40f else 0.68f
    val controlY = if (upper) 0.52f else 0.54f
    path.moveTo(size.width * 0.28f, size.height * startY)
    path.quadraticBezierTo(size.width * 0.50f, size.height * controlY, size.width * 0.78f, size.height * endY)
    drawPath(path, color, style = Stroke(width = 3.dp.toPx(), cap = StrokeCap.Round))
}

@Composable
private fun AmbientGlass(palette: SkinPalette) {
    Box(
        Modifier
            .size(330.dp)
            .background(palette.primary.copy(alpha = 0.035f), RoundedCornerShape(999.dp))
    )
}