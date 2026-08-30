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
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
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
import androidx.compose.ui.graphics.drawscope.rotate
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
        Column(
            Modifier
                .fillMaxSize()
                .statusBarsPadding()
                .navigationBarsPadding()
                .padding(18.dp)
        ) {
            Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                CollapseBrandMark(palette.primary, subtitle = stringResource(R.string.skin_title), compact = true, modifier = Modifier.weight(1f))
                OutlinedButton(onClick = onBack) { Text(stringResource(R.string.skin_back)) }
            }
            SkinPreview(preview, Modifier.fillMaxWidth().height(260.dp).padding(vertical = 14.dp))
            Text(
                "◆ ${profile.gemBalance} ${stringResource(R.string.skin_gem)}",
                color = Color.White.copy(alpha = 0.68f),
                fontSize = 15.sp,
                fontWeight = FontWeight.SemiBold,
                modifier = Modifier
                    .padding(bottom = 10.dp)
                    .background(Color.White.copy(alpha = 0.08f), RoundedCornerShape(99.dp))
                    .padding(horizontal = 14.dp, vertical = 8.dp)
            )
            LazyVerticalGrid(
                columns = GridCells.Fixed(2),
                modifier = Modifier.weight(1f),
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
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
            drawPreviewCapsule(palette.primary, rotationDegrees = -14f)
            drawPreviewCapsule(palette.secondary, rotationDegrees = 14f)
            drawCircle(palette.safe, 8.5.dp.toPx(), Offset(center.x + 72.dp.toPx(), center.y))
            drawCircle(palette.danger, 11.dp.toPx(), Offset(center.x + 48.dp.toPx(), center.y + 49.dp.toPx()), style = Stroke(3.dp.toPx()))
        }
        Text(
            skin.title.uppercase(),
            modifier = Modifier.align(Alignment.BottomCenter).padding(bottom = 16.dp),
            color = Color.White.copy(alpha = 0.85f),
            fontSize = 11.sp,
            fontWeight = FontWeight.SemiBold,
            letterSpacing = 3.sp
        )
    }
}

private fun androidx.compose.ui.graphics.drawscope.DrawScope.drawPreviewCapsule(color: Color, rotationDegrees: Float) {
    rotate(degrees = rotationDegrees, pivot = center) {
        val capsuleWidth = 110.dp.toPx()
        val capsuleHeight = 3.dp.toPx()
        drawRoundRect(
            color = color,
            topLeft = Offset(center.x - capsuleWidth / 2f, center.y - capsuleHeight / 2f),
            size = androidx.compose.ui.geometry.Size(capsuleWidth, capsuleHeight),
            cornerRadius = androidx.compose.ui.geometry.CornerRadius(capsuleHeight / 2f)
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
    val borderColor = if (selected) palette.primary.copy(alpha = 0.70f) else Color.White.copy(alpha = 0.08f)
    val borderWidth = if (selected) 1.5.dp else 1.dp
    Button(
        onClick = onClick,
        modifier = Modifier
            .fillMaxWidth()
            .border(borderWidth, borderColor, RoundedCornerShape(24.dp)),
        colors = ButtonDefaults.buttonColors(containerColor = if (selected) palette.primary.copy(alpha = 0.18f) else Color.White.copy(alpha = 0.06f)),
        shape = RoundedCornerShape(24.dp),
        contentPadding = ButtonDefaults.ContentPadding
    ) {
        Column(Modifier.padding(10.dp), horizontalAlignment = Alignment.Start, verticalArrangement = Arrangement.spacedBy(10.dp)) {
            Box(Modifier.fillMaxWidth().height(128.dp)) {
                Canvas(Modifier.fillMaxSize()) {
                    drawCircle(palette.primary.copy(alpha = 0.72f), 44.dp.toPx(), center, style = Stroke(2.dp.toPx()))
                    drawCircle(palette.primary, 4.5.dp.toPx(), Offset(center.x - 28.dp.toPx(), center.y))
                    drawCircle(palette.safe, 4.5.dp.toPx(), Offset(center.x + 28.dp.toPx(), center.y))
                }
                if (!unlocked) {
                    Text(
                        "🔒",
                        modifier = Modifier.align(Alignment.TopEnd).padding(4.dp),
                        fontSize = 13.sp
                    )
                }
            }
            Text(skin.title, color = Color.White, fontWeight = FontWeight.SemiBold, fontSize = 15.sp)
            Text(stringResource(skinDetailResource(skin)), color = Color.White.copy(alpha = 0.48f), fontSize = 12.sp)
            Text(accessLabel(skin, unlocked), color = if (unlocked) palette.safe else CollapseYellow, fontSize = 11.sp, textAlign = TextAlign.Start)
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