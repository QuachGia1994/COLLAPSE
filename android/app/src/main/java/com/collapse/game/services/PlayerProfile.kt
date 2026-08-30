package com.collapse.game.services

import android.content.Context
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.collapse.game.domain.GameMode
import com.collapse.game.ui.GameSkin
import com.collapse.game.ui.SkinAccess
import java.time.LocalDate

class PlayerProfile(context: Context) {
    private val preferences = context.getSharedPreferences("collapse.profile", Context.MODE_PRIVATE)

    var didCompleteTutorial by mutableStateOf(preferences.getBoolean(KEY_TUTORIAL, false))
        private set
    var dailyRunStreak by mutableIntStateOf(preferences.getInt(KEY_STREAK, 0))
        private set
    var gemBalance by mutableIntStateOf(preferences.getInt(KEY_GEMS, 0))
        private set
    var selectedSkin by mutableStateOf(readSelectedSkin())
        private set
    var selectedMode by mutableStateOf(readSelectedMode())
        private set
    var unlockedSkinIds by mutableStateOf(preferences.getStringSet(KEY_UNLOCKED, emptySet())?.toSet() ?: emptySet())
        private set
    var musicEnabled by mutableStateOf(preferences.getBoolean(KEY_MUSIC, true))
        private set
    var soundEnabled by mutableStateOf(preferences.getBoolean(KEY_SOUND, true))
        private set
    var hapticsEnabled by mutableStateOf(preferences.getBoolean(KEY_HAPTICS, true))
        private set

    val bestScore: Int
        get() = bestScore(selectedMode)
    val dailyBestScore: Int
        get() = dailyBestScore(selectedMode)

    init {
        migrateLegacyStatsIfNeeded()
    }

    fun completeTutorial() {
        didCompleteTutorial = true
        preferences.edit().putBoolean(KEY_TUTORIAL, true).apply()
    }

    fun selectMode(mode: GameMode) {
        selectedMode = mode
        preferences.edit().putString(KEY_MODE, mode.name).apply()
    }

    fun updateMusicEnabled(enabled: Boolean) {
        musicEnabled = enabled
        preferences.edit().putBoolean(KEY_MUSIC, enabled).apply()
    }

    fun updateSoundEnabled(enabled: Boolean) {
        soundEnabled = enabled
        preferences.edit().putBoolean(KEY_SOUND, enabled).apply()
    }

    fun updateHapticsEnabled(enabled: Boolean) {
        hapticsEnabled = enabled
        preferences.edit().putBoolean(KEY_HAPTICS, enabled).apply()
    }

    fun registerRunStart(today: LocalDate = LocalDate.now()) {
        val last = preferences.getString(KEY_LAST_RUN_DATE, null)?.let(LocalDate::parse)
        if (last == today) return
        dailyRunStreak = if (last == today.minusDays(1)) maxOf(1, dailyRunStreak + 1) else 1
        clearDailyModeScores()
        preferences.edit()
            .putInt(KEY_STREAK, dailyRunStreak)
            .putString(KEY_LAST_RUN_DATE, today.toString())
            .apply()
    }

    fun record(score: Int, gemsEarned: Int, mode: GameMode) {
        if (!mode.isCompetitive) return
        val best = maxOf(bestScore(mode), score)
        val daily = maxOf(dailyBestScore(mode), score)
        val top = if (score > 0) (topScores(mode) + score).sortedDescending().take(3) else topScores(mode)
        gemBalance += maxOf(0, gemsEarned)
        preferences.edit()
            .putInt(bestKey(mode), best)
            .putInt(dailyBestKey(mode), daily)
            .putString(topScoresKey(mode), top.joinToString(","))
            .putInt(KEY_GEMS, gemBalance)
            .apply()
    }

    fun bestScore(mode: GameMode): Int = preferences.getInt(bestKey(mode), 0)

    fun dailyBestScore(mode: GameMode): Int = preferences.getInt(dailyBestKey(mode), 0)

    fun topScores(mode: GameMode): List<Int> = preferences
        .getString(topScoresKey(mode), null)
        ?.split(',')
        ?.mapNotNull(String::toIntOrNull)
        ?.sortedDescending()
        ?.take(3)
        ?: emptyList()

    fun localRank(score: Int, mode: GameMode = selectedMode): Int? {
        if (score <= 0) return null
        val projected = (topScores(mode) + score).sortedDescending()
        return projected.indexOf(score).takeIf { it >= 0 }?.plus(1)
    }

    fun selectSkin(skin: GameSkin, isPlusUnlocked: Boolean): Boolean {
        if (!isUnlocked(skin, isPlusUnlocked)) return false
        selectedSkin = skin
        preferences.edit().putString(KEY_SKIN, skin.name).apply()
        return true
    }

    fun unlock(skin: GameSkin): Boolean {
        val access = skin.access as? SkinAccess.Gems ?: return false
        if (unlockedSkinIds.contains(skin.name)) return true
        if (gemBalance < access.cost) return false
        gemBalance -= access.cost
        unlockedSkinIds = unlockedSkinIds + skin.name
        preferences.edit()
            .putInt(KEY_GEMS, gemBalance)
            .putStringSet(KEY_UNLOCKED, unlockedSkinIds)
            .apply()
        return true
    }

    fun isUnlocked(skin: GameSkin, isPlusUnlocked: Boolean): Boolean = when (skin.access) {
        SkinAccess.Free -> true
        is SkinAccess.Gems -> unlockedSkinIds.contains(skin.name)
        SkinAccess.Plus -> isPlusUnlocked
    }

    fun activeSkin(isPlusUnlocked: Boolean): GameSkin =
        if (isUnlocked(selectedSkin, isPlusUnlocked)) selectedSkin else GameSkin.Classic

    private fun migrateLegacyStatsIfNeeded() {
        val classic = GameMode.Classic
        val editor = preferences.edit()
        if (!preferences.contains(bestKey(classic))) {
            editor.putInt(bestKey(classic), preferences.getInt(KEY_LEGACY_BEST, 0))
        }
        if (!preferences.contains(dailyBestKey(classic))) {
            editor.putInt(dailyBestKey(classic), preferences.getInt(KEY_LEGACY_DAILY_BEST, 0))
        }
        editor.apply()
    }

    private fun clearDailyModeScores() {
        val editor = preferences.edit()
        GameMode.entries.forEach { editor.remove(dailyBestKey(it)) }
        editor.apply()
    }

    private fun bestKey(mode: GameMode) = "mode.best.${mode.name}"
    private fun dailyBestKey(mode: GameMode) = "mode.daily.${mode.name}"
    private fun topScoresKey(mode: GameMode) = "mode.top.${mode.name}"

    private fun readSelectedSkin(): GameSkin {
        val raw = preferences.getString(KEY_SKIN, null) ?: return GameSkin.Classic
        return GameSkin.entries.firstOrNull { it.name == raw } ?: GameSkin.Classic
    }

    private fun readSelectedMode(): GameMode {
        val raw = preferences.getString(KEY_MODE, null) ?: return GameMode.Classic
        return GameMode.entries.firstOrNull { it.name == raw } ?: GameMode.Classic
    }

    private companion object {
        const val KEY_TUTORIAL = "tutorial.completed"
        const val KEY_LEGACY_BEST = "best.score"
        const val KEY_LEGACY_DAILY_BEST = "daily.best"
        const val KEY_STREAK = "daily.streak"
        const val KEY_LAST_RUN_DATE = "daily.lastRun"
        const val KEY_GEMS = "economy.gems"
        const val KEY_SKIN = "skin.selected"
        const val KEY_UNLOCKED = "skin.unlocked"
        const val KEY_MODE = "mode.selected"
        const val KEY_MUSIC = "audio.music"
        const val KEY_SOUND = "audio.sound"
        const val KEY_HAPTICS = "audio.haptics"
    }
}
