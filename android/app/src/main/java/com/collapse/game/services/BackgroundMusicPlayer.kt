package com.collapse.game.services

import android.content.Context
import android.media.MediaPlayer
import android.os.PowerManager
import com.collapse.game.R

/** Owns the single foreground background-music player for the Android app. */
class BackgroundMusicPlayer(context: Context) : AutoCloseable {
    private val appContext = context.applicationContext
    private val powerManager = appContext.getSystemService(PowerManager::class.java)
    private var player: MediaPlayer? = null

    fun play() {
        val mediaPlayer = player ?: createPlayer()?.also { player = it } ?: return
        refreshVolume()
        if (!mediaPlayer.isPlaying) mediaPlayer.start()
    }

    fun pause() {
        val mediaPlayer = player ?: return
        if (mediaPlayer.isPlaying) mediaPlayer.pause()
    }

    fun refreshVolume() {
        val volume = if (powerManager?.isPowerSaveMode == true) LOW_POWER_VOLUME else NORMAL_VOLUME
        player?.setVolume(volume, volume)
    }

    override fun close() {
        player?.release()
        player = null
    }

    private fun createPlayer(): MediaPlayer? = MediaPlayer.create(appContext, R.raw.collapse_arcade_vibe)?.apply {
        isLooping = true
    }


    private companion object {
        const val NORMAL_VOLUME = 0.18f
        const val LOW_POWER_VOLUME = 0.10f
    }
}
