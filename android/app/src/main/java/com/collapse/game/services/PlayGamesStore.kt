package com.collapse.game.services

import android.app.Activity
import android.content.Context
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.collapse.game.R
import com.collapse.game.domain.GameMode
import com.google.android.gms.games.PlayGames
import com.google.android.gms.games.PlayGamesSdk
import com.google.android.gms.games.leaderboard.LeaderboardVariant
import com.google.android.gms.tasks.Task
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException
import kotlin.coroutines.suspendCoroutine

enum class PlayGamesConnectionState {
    Unavailable,
    NeedsAuthentication,
    Connecting,
    Connected
}

class PlayGamesStore(private val activity: Activity) {
    private val preferences = activity.getSharedPreferences("collapse.playgames", Context.MODE_PRIVATE)
    private val pendingScores = readPendingScores().toMutableMap()
    private val ranks = mutableStateMapOf<GameMode, Int>()

    var state by mutableStateOf(PlayGamesConnectionState.Connecting)
        private set
    var lastError by mutableStateOf<String?>(null)
        private set

    val configured: Boolean
        get() = activity.getString(R.string.game_services_project_id) != "0"

    init {
        if (configured) {
            PlayGamesSdk.initialize(activity.applicationContext)
        } else {
            state = PlayGamesConnectionState.Unavailable
        }
    }

    suspend fun refresh(mode: GameMode) {
        if (!mode.isCompetitive) {
            ranks.remove(mode)
            return
        }
        if (!ensureAuthenticated()) return
        val id = leaderboardId(mode) ?: return

        runCatching {
            val annotated = PlayGames.getLeaderboardsClient(activity)
                .loadCurrentPlayerLeaderboardScore(
                    id,
                    LeaderboardVariant.TIME_SPAN_ALL_TIME,
                    LeaderboardVariant.COLLECTION_PUBLIC
                )
                .awaitResult()
            annotated.get()?.rank?.toInt()
        }.onSuccess { rank ->
            if (rank == null || rank <= 0) ranks.remove(mode) else ranks[mode] = rank
            lastError = null
        }.onFailure { error ->
            lastError = error.message
        }
    }

    suspend fun connect() {
        if (!configured) {
            state = PlayGamesConnectionState.Unavailable
            return
        }
        state = PlayGamesConnectionState.Connecting
        runCatching {
            PlayGames.getGamesSignInClient(activity).signIn().awaitResult()
        }.onSuccess {
            state = PlayGamesConnectionState.Connected
            lastError = null
            retryPending()
        }.onFailure { error ->
            state = PlayGamesConnectionState.NeedsAuthentication
            lastError = error.message
        }
    }

    suspend fun submit(score: Int, mode: GameMode) {
        if (score <= 0 || !mode.isCompetitive) return
        if (!ensureAuthenticated()) {
            queue(score, mode)
            return
        }
        val id = leaderboardId(mode) ?: run {
            queue(score, mode)
            return
        }

        runCatching {
            PlayGames.getLeaderboardsClient(activity)
                .submitScoreImmediate(id, score.toLong())
                .awaitResult()
        }.onSuccess {
            pendingScores.remove(mode.name)
            persistPendingScores()
            refresh(mode)
        }.onFailure { error ->
            queue(score, mode)
            lastError = error.message
        }
    }

    fun remoteRank(mode: GameMode): Int? = ranks[mode]

    suspend fun retryPending() {
        if (!ensureAuthenticated()) return
        val snapshot = pendingScores.toMap()
        snapshot.forEach { (rawMode, score) ->
            val mode = GameMode.entries.firstOrNull { it.name == rawMode } ?: return@forEach
            submit(score, mode)
        }
    }

    private suspend fun ensureAuthenticated(): Boolean {
        if (!configured) {
            state = PlayGamesConnectionState.Unavailable
            return false
        }
        state = PlayGamesConnectionState.Connecting
        return runCatching {
            PlayGames.getGamesSignInClient(activity).isAuthenticated.awaitResult().isAuthenticated
        }.fold(
            onSuccess = { authenticated ->
                state = if (authenticated) PlayGamesConnectionState.Connected else PlayGamesConnectionState.NeedsAuthentication
                authenticated
            },
            onFailure = { error ->
                state = PlayGamesConnectionState.Unavailable
                lastError = error.message
                false
            }
        )
    }

    private fun leaderboardId(mode: GameMode): String? {
        val value = when (mode) {
            GameMode.Classic -> activity.getString(R.string.leaderboard_classic_id)
            GameMode.Rush -> activity.getString(R.string.leaderboard_rush_id)
            GameMode.Precision -> activity.getString(R.string.leaderboard_precision_id)
            GameMode.Daily -> activity.getString(R.string.leaderboard_daily_id)
            GameMode.Zen -> return null
        }
        return value.takeIf { it.isNotBlank() && it != "0" }
    }

    private fun queue(score: Int, mode: GameMode) {
        pendingScores[mode.name] = maxOf(pendingScores[mode.name] ?: 0, score)
        persistPendingScores()
    }

    private fun readPendingScores(): Map<String, Int> {
        val result = mutableMapOf<String, Int>()
        GameMode.entries.forEach { mode ->
            val score = preferences.getInt("pending.${mode.name}", 0)
            if (score > 0) result[mode.name] = score
        }
        return result
    }

    private fun persistPendingScores() {
        val editor = preferences.edit().clear()
        pendingScores.forEach { (mode, score) -> editor.putInt("pending.$mode", score) }
        editor.apply()
    }
}

private suspend fun <T> Task<T>.awaitResult(): T = suspendCoroutine { continuation ->
    addOnCompleteListener { task ->
        when {
            task.isSuccessful -> continuation.resume(task.result)
            task.isCanceled -> continuation.resumeWithException(IllegalStateException("Play Games task cancelled"))
            else -> continuation.resumeWithException(task.exception ?: IllegalStateException("Play Games task failed"))
        }
    }
}
