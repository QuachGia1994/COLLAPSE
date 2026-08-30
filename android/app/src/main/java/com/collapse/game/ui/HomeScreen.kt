package com.collapse.game.ui

import androidx.appcompat.app.AppCompatDelegate
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.rotate
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.os.LocaleListCompat
import com.collapse.game.R
import com.collapse.game.domain.GameMode
import com.collapse.game.services.PlayGamesConnectionState
import com.collapse.game.services.PlayGamesStore
import com.collapse.game.services.PlayerProfile
import kotlinx.coroutines.launch
import java.util.Locale

@Composable
fun HomeScreen(
    profile: PlayerProfile,
    playGames: PlayGamesStore,
    isPlusUnlocked: Boolean,
    onPlay: () -> Unit,
    onSkins: () -> Unit,
    onPlus: () -> Unit,
    onTutorial: () -> Unit
) {
    val skin = profile.activeSkin(isPlusUnlocked)
    LaunchedEffect(profile.selectedMode) { playGames.refresh(profile.selectedMode) }

    Box(
        Modifier
            .fillMaxSize()
            .background(Brush.verticalGradient(listOf(skin.palette.backgroundTop, skin.palette.backgroundBottom)))
    ) {
        AmbientGlass(skin.palette)
        Column(
            modifier = Modifier
                .fillMaxSize()
                .statusBarsPadding()
                .navigationBarsPadding()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 20.dp, vertical = 16.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Top
        ) {
            HomeHeader(skin, onTutorial, profile)
            Spacer(Modifier.height(16.dp))
            HomeOrb(skin)
            Spacer(Modifier.height(16.dp))
            ModePicker(profile, skin)
            Spacer(Modifier.height(16.dp))
            HomeActions(skin, onPlay, onSkins, onPlus, onTutorial)
            Spacer(Modifier.height(16.dp))
            HomeMetrics(profile, playGames, skin)
            Spacer(Modifier.height(20.dp))
        }
    }
}

@Composable
private fun HomeHeader(skin: GameSkin, onTutorial: () -> Unit, profile: PlayerProfile) {
    Row(
        modifier = Modifier.fillMaxWidth().widthIn(max = 380.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        CollapseBrandMark(
            tint = skin.palette.primary,
            subtitle = stringResource(R.string.brand_subtitle),
            compact = true,
            modifier = Modifier.weight(1f)
        )
        HeaderGlassButton(onTutorial, "?", Color.White, contentDescription = stringResource(R.string.home_tutorial))
        AudioMenu(profile, skin)
        LanguageMenu(skin)
    }
}

@Composable
private fun HeaderGlassButton(onClick: () -> Unit, glyph: String, tint: Color, contentDescription: String) {
    Box(
        modifier = Modifier
            .size(42.dp)
            .background(Color.White.copy(alpha = 0.08f), CircleShape)
            .border(1.dp, Color.White.copy(alpha = 0.14f), CircleShape)
            .clickable(onClick = onClick),
        contentAlignment = Alignment.Center
    ) {
        Text(glyph, color = tint, fontSize = 13.sp, fontWeight = FontWeight.Bold)
    }
}

@Composable
private fun AudioMenu(profile: PlayerProfile, skin: GameSkin) {
    var expanded by remember { mutableStateOf(false) }
    Box {
        Box(
            modifier = Modifier
                .size(42.dp)
                .background(Color.White.copy(alpha = 0.08f), CircleShape)
                .border(1.dp, Color.White.copy(alpha = 0.14f), CircleShape)
                .clickable { expanded = true },
            contentAlignment = Alignment.Center
        ) {
            Text("♪", color = skin.palette.primary, fontSize = 13.sp, fontWeight = FontWeight.Bold)
        }
        DropdownMenu(expanded = expanded, onDismissRequest = { expanded = false }) {
            AudioToggle(stringResource(R.string.settings_music), profile.musicEnabled) {
                profile.updateMusicEnabled(it)
            }
            AudioToggle(stringResource(R.string.settings_sound), profile.soundEnabled) {
                profile.updateSoundEnabled(it)
            }
            AudioToggle(stringResource(R.string.settings_haptics), profile.hapticsEnabled) {
                profile.updateHapticsEnabled(it)
            }
        }
    }
}

@Composable
private fun AudioToggle(label: String, checked: Boolean, onChange: (Boolean) -> Unit) {
    DropdownMenuItem(
        text = {
            Text(
                if (checked) "✓ $label" else label,
                color = if (checked) Color.White else Color.White.copy(alpha = 0.62f),
                fontSize = 14.sp
            )
        },
        onClick = { onChange(!checked) }
    )
}

@Composable
private fun LanguageMenu(skin: GameSkin) {
    var expanded by remember { mutableStateOf(false) }
    val appLocale = AppCompatDelegate.getApplicationLocales().get(0)?.toLanguageTag()
    val currentTag = appLocale ?: Locale.getDefault().toLanguageTag()
    val currentLabel = when {
        currentTag.startsWith("vi") -> "VI"
        currentTag.startsWith("ja") -> "JA"
        currentTag.startsWith("zh") -> "中文"
        else -> "EN"
    }

    Box {
        Box(
            modifier = Modifier
                .size(42.dp)
                .background(Color.White.copy(alpha = 0.08f), CircleShape)
                .border(1.dp, Color.White.copy(alpha = 0.14f), CircleShape)
                .clickable { expanded = true },
            contentAlignment = Alignment.Center
        ) {
            Text("◎ $currentLabel", color = skin.palette.primary, fontSize = 11.sp, fontWeight = FontWeight.SemiBold)
        }
        DropdownMenu(expanded = expanded, onDismissRequest = { expanded = false }) {
            LanguageOption("English", "en") { expanded = false }
            LanguageOption("Tiếng Việt", "vi") { expanded = false }
            LanguageOption("日本語", "ja") { expanded = false }
            LanguageOption("简体中文", "zh-Hans") { expanded = false }
        }
    }
}

@Composable
private fun LanguageOption(label: String, tag: String, onDone: () -> Unit) {
    DropdownMenuItem(
        text = { Text(label) },
        onClick = {
            AppCompatDelegate.setApplicationLocales(LocaleListCompat.forLanguageTags(tag))
            onDone()
        }
    )
}

@Composable
private fun ModePicker(profile: PlayerProfile, skin: GameSkin) {
    GlassSurface(modifier = Modifier.fillMaxWidth().widthIn(max = 380.dp), radius = 22.dp) {
        Column(Modifier.padding(13.dp), verticalArrangement = Arrangement.spacedBy(9.dp)) {
            Text(
                "${stringResource(R.string.home_mode)} · ${profile.selectedMode.title}",
                color = Color.White,
                fontSize = 12.sp,
                fontWeight = FontWeight.SemiBold,
                letterSpacing = 1.4.sp
            )
            Text(
                stringResource(modeDetailResource(profile.selectedMode)),
                color = Color.White.copy(alpha = 0.52f),
                fontSize = 12.sp
            )
            Row(
                Modifier.horizontalScroll(rememberScrollState()),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                GameMode.entries.forEach { mode ->
                    OutlinedButton(
                        onClick = { profile.selectMode(mode) },
                        shape = RoundedCornerShape(99.dp),
                        colors = ButtonDefaults.outlinedButtonColors(
                            contentColor = if (profile.selectedMode == mode) skin.palette.primary else Color.White.copy(alpha = 0.70f)
                        )
                    ) {
                        Text(mode.title, fontSize = 11.sp, fontWeight = FontWeight.SemiBold)
                    }
                }
            }
        }
    }
}

@Composable
private fun HomeActions(
    skin: GameSkin,
    onPlay: () -> Unit,
    onSkins: () -> Unit,
    onPlus: () -> Unit,
    onTutorial: () -> Unit
) {
    GlassSurface(modifier = Modifier.fillMaxWidth().widthIn(max = 380.dp), radius = 22.dp) {
        Column(Modifier.padding(13.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
            Button(
                onClick = onPlay,
                modifier = Modifier.fillMaxWidth().height(56.dp),
                colors = ButtonDefaults.buttonColors(containerColor = skin.palette.primary),
                shape = RoundedCornerShape(28.dp)
            ) {
                Text("▶  ${stringResource(R.string.home_play)}", color = Color.Black, fontSize = 18.sp, fontWeight = FontWeight.Medium)
            }
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                OutlinedButton(onClick = onSkins, modifier = Modifier.weight(1f), shape = RoundedCornerShape(24.dp)) {
                    Text("◉  ${stringResource(R.string.home_skin)}", color = skin.palette.primary, fontSize = 15.sp)
                }
                Button(
                    onClick = onPlus,
                    modifier = Modifier.weight(1f),
                    colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF514A08)),
                    shape = RoundedCornerShape(24.dp)
                ) {
                    Text("◆  ${stringResource(R.string.home_plus)}", color = CollapseYellow, fontSize = 15.sp)
                }
            }
            OutlinedButton(onClick = onTutorial, modifier = Modifier.fillMaxWidth(), shape = RoundedCornerShape(24.dp)) {
                Text("?  ${stringResource(R.string.home_tutorial)}", color = Color.White.copy(alpha = 0.82f), fontSize = 14.sp)
            }
        }
    }
}

@Composable
private fun HomeMetrics(profile: PlayerProfile, playGames: PlayGamesStore, skin: GameSkin) {
    val mode = profile.selectedMode
    val scope = rememberCoroutineScope()

    GlassSurface(modifier = Modifier.fillMaxWidth().widthIn(max = 380.dp), radius = 22.dp) {
        Column(Modifier.padding(horizontal = 13.dp, vertical = 12.dp), verticalArrangement = Arrangement.spacedBy(9.dp)) {
            Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                Text(
                    "${mode.title} · ${stringResource(R.string.home_stats)}",
                    color = Color.White,
                    fontSize = 11.sp,
                    fontWeight = FontWeight.SemiBold,
                    letterSpacing = 1.2.sp
                )
                Spacer(Modifier.weight(1f))
                RankBadge(profile, playGames, skin) { scope.launch { playGames.connect(); playGames.refresh(mode) } }
            }
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceEvenly,
                verticalAlignment = Alignment.CenterVertically
            ) {
                MetricBlock(stringResource(R.string.home_best), profile.bestScore(mode).toString(), Modifier.weight(1f))
                MetricBlock(stringResource(R.string.home_today), profile.dailyBestScore(mode).toString(), Modifier.weight(1f))
                MetricBlock(stringResource(R.string.home_streak), "🔥${profile.dailyRunStreak}", Modifier.weight(1f))
                MetricBlock(stringResource(R.string.home_gems), "◆${profile.gemBalance}", Modifier.weight(1f))
            }
            Text(
                stringResource(R.string.home_account_hint, mode.title),
                color = Color.White.copy(alpha = 0.42f),
                fontSize = 9.sp,
                modifier = Modifier.align(Alignment.CenterHorizontally)
            )
        }
    }
}

@Composable
private fun RankBadge(
    profile: PlayerProfile,
    playGames: PlayGamesStore,
    skin: GameSkin,
    onConnect: () -> Unit
) {
    val mode = profile.selectedMode
    if (!mode.isCompetitive) {
        Text(stringResource(R.string.home_rank_zen), color = Color.White.copy(alpha = 0.48f), fontSize = 9.sp, fontWeight = FontWeight.SemiBold)
        return
    }

    val remote = playGames.remoteRank(mode)
    if (remote != null) {
        Text(stringResource(R.string.home_rank_play_games, remote), color = Color(0xFF59E18C), fontSize = 9.sp, fontWeight = FontWeight.SemiBold)
        return
    }

    val local = profile.localRank(profile.bestScore(mode), mode)
    if (local != null) {
        Text(stringResource(R.string.home_rank_local, local), color = skin.palette.primary, fontSize = 9.sp, fontWeight = FontWeight.SemiBold)
        return
    }

    if (playGames.configured && playGames.state == PlayGamesConnectionState.NeedsAuthentication) {
        OutlinedButton(onClick = onConnect, shape = RoundedCornerShape(99.dp)) {
            Text(stringResource(R.string.home_rank_connect), fontSize = 9.sp)
        }
    } else {
        Text(stringResource(R.string.home_rank_offline), color = Color.White.copy(alpha = 0.42f), fontSize = 8.sp)
    }
}

@Composable
private fun HomeOrb(skin: GameSkin) {
    Canvas(Modifier.size(214.dp)) {
        val center = Offset(size.width / 2f, size.height / 2f)
        val radius = size.minDimension * 0.46f
        drawCircle(Color.White.copy(alpha = 0.07f), radius, center)
        drawCircle(skin.palette.primary.copy(alpha = 0.34f), radius, center, style = Stroke(width = 2.dp.toPx()))
        drawOrbCapsule(skin.palette.primary, rotationDegrees = -17f)
        drawOrbCapsule(skin.palette.secondary, rotationDegrees = 20f)
        drawCircle(skin.palette.primary, 8.dp.toPx(), Offset(size.width * 0.12f, size.height * 0.52f))
        drawCircle(skin.palette.safe, 8.5.dp.toPx(), Offset(size.width * 0.88f, size.height * 0.28f))
        drawCircle(skin.palette.danger, 11.dp.toPx(), Offset(size.width * 0.78f, size.height * 0.76f), style = Stroke(width = 3.dp.toPx()))
    }
}

private fun androidx.compose.ui.graphics.drawscope.DrawScope.drawOrbCapsule(color: Color, rotationDegrees: Float) {
    rotate(degrees = rotationDegrees, pivot = center) {
        val capsuleWidth = 150.dp.toPx()
        val capsuleHeight = 3.dp.toPx()
        drawRoundRect(
            color = color,
            topLeft = Offset(center.x - capsuleWidth / 2f, center.y - capsuleHeight / 2f),
            size = Size(capsuleWidth, capsuleHeight),
            cornerRadius = CornerRadius(capsuleHeight / 2f)
        )
    }
}

@Composable
private fun AmbientGlass(palette: SkinPalette) {
    Box(
        Modifier
            .size(330.dp)
            .background(palette.primary.copy(alpha = 0.035f), RoundedCornerShape(999.dp))
    )
}

private fun modeDetailResource(mode: GameMode): Int = when (mode) {
    GameMode.Classic -> R.string.mode_classic_detail
    GameMode.Rush -> R.string.mode_rush_detail
    GameMode.Precision -> R.string.mode_precision_detail
    GameMode.Daily -> R.string.mode_daily_detail
    GameMode.Zen -> R.string.mode_zen_detail
}
