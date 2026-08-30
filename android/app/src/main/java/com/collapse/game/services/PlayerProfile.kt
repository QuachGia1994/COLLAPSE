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
    var bestScore by mutableIntStateOf(preferences.getInt(KEY_BEST, 0))
        private set
    var dailyBestScore by mutableIntStateOf(preferences.getInt(KEY_DAILY_BEST, 0))
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

    fun completeTutorial() {
        didCompleteTutorial = true
        preferences.edit().putBoolean(KEY_TUTORIAL, true).apply()
    }

    fun selectMode(mode: GameMode) {
        selectedMode = mode
        preferences.edit().putString(KEY_MODE, mode.name).apply()
    }

    fun registerRunStart(today: LocalDate = LocalDate.now()) {
        val last = preferences.getString(KEY_LAST_RUN_DATE, null)?.let(LocalDate::parse)
        if (last == today) return
        dailyRunStreak = if (last == today.minusDays(1)) maxOf(1, dailyRunStreak + 1) else 1
        dailyBestScore = 0
        preferences.edit()
            .putInt(KEY_STREAK, dailyRunStreak)
            .putInt(KEY_DAILY_BEST, 0)
            .putString(KEY_LAST_RUN_DATE, today.toString())
            .apply()
    }

    fun record(score: Int, gemsEarned: Int) {
        bestScore = maxOf(bestScore, score)
        dailyBestScore = maxOf(dailyBestScore, score)
        gemBalance += maxOf(0, gemsEarned)
        preferences.edit()
            .putInt(KEY_BEST, bestScore)
            .putInt(KEY_DAILY_BEST, dailyBestScore)
            .putInt(KEY_GEMS, gemBalance)
            .apply()
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
        const val KEY_BEST = "best.score"
        const val KEY_DAILY_BEST = "daily.best"
        const val KEY_STREAK = "daily.streak"
        const val KEY_LAST_RUN_DATE = "daily.lastRun"
        const val KEY_GEMS = "economy.gems"
        const val KEY_SKIN = "skin.selected"
        const val KEY_UNLOCKED = "skin.unlocked"
        const val KEY_MODE = "mode.selected"
    }
}