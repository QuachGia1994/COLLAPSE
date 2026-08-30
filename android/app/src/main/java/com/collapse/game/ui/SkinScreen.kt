package com.collapse.game.ui

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.collapse.game.R
import com.collapse.game.services.PlayerProfile

@Composable
fun SkinScreen(
    profile: PlayerProfile,
    isPlusUnlocked: Boolean,
    onBack: () -> Unit,
    onPlus: () -> Unit
) {
    var preview by remember { mutableStateOf(profile.activeSkin(isPlusUnlocked)) }
    var showsInsufficientGems by remember { mutableStateOf(false) }
    val palette = preview.palette
    Box(Modifier.fillMaxSize().background(Brush.verticalGradient(listOf(palette.backgroundTop, palette.backgroundBottom)))) {
        Column(Modifier.fillMaxSize().padding(horizontal = 18.dp, vertical = 34.dp)) {
            Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                CollapseBrandMark(palette.primary, subtitle = stringResource(R.string.skin_title), compact = true, modifier = Modifier.weight(1f))
                OutlinedButton(onClick = onBack) { Text(stringResource(R.string.skin_back)) }
            }
            SkinPreview(preview, Modifier.fillMaxWidth().height(230.dp).padding(vertical = 14.dp))
            Text("◆ ${profile.gemBalance} ${stringResource(R.string.skin_gem)}", color = Color.White.copy(alpha = 0.68f), fontSize = 12.sp, modifier = Modifier.padding(bottom = 10.dp))
            LazyVerticalGrid(
                columns = GridCells.Fixed(2),
                modifier = Modifier.weight(1f),
                horizontalArrangement = Arrangement.spacedBy(10.dp),
                verticalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                items(GameSkin.entries) { skin ->
                    SkinCard(
                        skin = skin,
                        selected = profile.selectedSkin == skin,
                        unlocked = profile.isUnlocked(skin, isPlusUnlocked),
                        onClick = {
                            preview = skin
                            chooseSkin(
                                profile = profile,
                                skin = skin,
                                isPlusUnlocked = isPlusUnlocked,
                                onPlus = onPlus,
                                onInsufficientGems = { showsInsufficientGems = true }
                            )
                        }
                    )
                }
            }
            if (!isPlusUnlocked) {
                Button(
                    onClick = onPlus,
                    modifier = Modifier.fillMaxWidth().padding(top = 12.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = CollapseYellow)
                ) {
                    Text(stringResource(R.string.skin_open_plus), color = Color.Black, fontWeight = FontWeight.SemiBold)
                }
            }
        }
        if (showsInsufficientGems) {
            AlertDialog(
                onDismissRequest = { showsInsufficientGems = false },
                title = { Text(stringResource(R.string.skin_insufficient_title)) },
                text = { Text(stringResource(R.string.skin_insufficient_message)) },
                confirmButton = {
                    TextButton(onClick = { showsInsufficientGems = false }) { Text("OK") }
                }
            )
        }
    }
}

private fun chooseSkin(
    profile: PlayerProfile,
    skin: GameSkin,
    isPlusUnlocked: Boolean,
    onPlus: () -> Unit,
    onInsufficientGems: () -> Unit
) {
    if (profile.isUnlocked(skin, isPlusUnlocked)) {
        profile.selectSkin(skin, isPlusUnlocked)
        return
    }
    when (skin.access) {
        is SkinAccess.Gems -> if (profile.unlock(skin)) {
            profile.selectSkin(skin, isPlusUnlocked)
        } else {
            onInsufficientGems()
        }
        SkinAccess.Plus -> onPlus()
        SkinAccess.Free -> profile.selectSkin(skin, isPlusUnlocked)
    }
}

@Composable
private fun SkinPreview(skin: GameSkin, modifier: Modifier) {
    val palette = skin.palette
    Box(
        modifier
            .background(Brush.linearGradient(listOf(palette.backgroundTop, palette.backgroundBottom)), RoundedCornerShape(30.dp))
            .border(1.dp, palette.primary.copy(alpha = 0.24f), RoundedCornerShape(30.dp)),
        contentAlignment = Alignment.Center
    ) {
        Canvas(Modifier.size(190.dp)) {
            drawCircle(palette.primary.copy(alpha = 0.10f), size.minDimension * 0.48f)
            drawCircle(palette.primary.copy(alpha = 0.65f), size.minDimension * 0.46f, style = Stroke(width = 2.dp.toPx()))
            val upper = Path().apply {
                moveTo(size.width * 0.20f, size.height * 0.58f)
                quadraticBezierTo(size.width * 0.50f, size.height * 0.32f, size.width * 0.80f, size.height * 0.42f)
            }
            val lower = Path().apply {
                moveTo(size.width * 0.20f, size.height * 0.42f)
                quadraticBezierTo(size.width * 0.50f, size.height * 0.70f, size.width * 0.80f, size.height * 0.60f)
            }
            drawPath(upper, palette.primary, style = Stroke(3.dp.toPx(), cap = StrokeCap.Round))
            drawPath(lower, palette.secondary, style = Stroke(3.dp.toPx(), cap = StrokeCap.Round))
            drawCircle(palette.safe, 8.dp.toPx(), Offset(size.width * 0.82f, size.height * 0.38f))
            drawCircle(palette.danger, 10.dp.toPx(), Offset(size.width * 0.76f, size.height * 0.68f), style = Stroke(3.dp.toPx()))
        }
        Text(
            skin.title.uppercase(),
            modifier = Modifier.align(Alignment.BottomCenter).padding(bottom = 14.dp),
            color = Color.White.copy(alpha = 0.84f),
            fontSize = 11.sp,
            fontWeight = FontWeight.SemiBold,
            letterSpacing = 2.sp
        )
    }
}

@Composable
private fun SkinCard(
    skin: GameSkin,
    selected: Boolean,
    unlocked: Boolean,
    onClick: () -> Unit
) {
    val palette = skin.palette
    Button(
        onClick = onClick,
        modifier = Modifier.fillMaxWidth(),
        colors = ButtonDefaults.buttonColors(containerColor = if (selected) palette.primary.copy(alpha = 0.18f) else Color.White.copy(alpha = 0.06f)),
        shape = RoundedCornerShape(22.dp),
        contentPadding = ButtonDefaults.ContentPadding
    ) {
        Column(Modifier.padding(vertical = 8.dp), horizontalAlignment = Alignment.Start) {
            Box(Modifier.fillMaxWidth().height(82.dp)) {
                Canvas(Modifier.fillMaxSize()) {
                    drawCircle(palette.primary.copy(alpha = 0.72f), 34.dp.toPx(), center, style = Stroke(2.dp.toPx()))
                    drawCircle(palette.primary, 5.dp.toPx(), Offset(center.x - 24.dp.toPx(), center.y))
                    drawCircle(palette.safe, 5.dp.toPx(), Offset(center.x + 24.dp.toPx(), center.y - 12.dp.toPx()))
                }
                if (!unlocked) {
                    Text(
                        "🔒",
                        modifier = Modifier.align(Alignment.TopEnd).padding(4.dp),
                        fontSize = 13.sp
                    )
                }
            }
            Text(skin.title, color = Color.White, fontWeight = FontWeight.SemiBold, fontSize = 14.sp)
            Text(stringResource(skinDetailResource(skin)), color = Color.White.copy(alpha = 0.48f), fontSize = 11.sp)
            Text(accessLabel(skin, unlocked), color = if (unlocked) palette.safe else CollapseYellow, fontSize = 10.sp, textAlign = TextAlign.Start)
        }
    }
}

private fun skinDetailResource(skin: GameSkin): Int = when (skin) {
    GameSkin.Classic -> R.string.skin_classic_detail
    GameSkin.Nebula -> R.string.skin_nebula_detail
    GameSkin.Aurora -> R.string.skin_aurora_detail
    GameSkin.Solar -> R.string.skin_solar_detail
    GameSkin.Obsidian -> R.string.skin_obsidian_detail
    GameSkin.FrozenQuartz -> R.string.skin_frozen_detail
}

@Composable
private fun accessLabel(skin: GameSkin, unlocked: Boolean): String {
    if (unlocked) return stringResource(R.string.skin_unlocked)
    return when (val access = skin.access) {
        SkinAccess.Free -> "FREE"
        is SkinAccess.Gems -> "◆ ${access.cost} ${stringResource(R.string.skin_gem)}"
        SkinAccess.Plus -> "◆ PLUS"
    }
}