package com.collapse.game.services

import android.content.Context
import android.media.AudioManager
import android.media.ToneGenerator
import android.os.VibrationEffect
import android.os.Vibrator
import com.collapse.game.domain.SensoryClient

class SensoryEngine(context: Context) : SensoryClient, AutoCloseable {
    private val vibrator = context.getSystemService(Vibrator::class.java)
    private val tone = ToneGenerator(AudioManager.STREAM_MUSIC, 36)
    var soundEnabled: Boolean = true
    var hapticsEnabled: Boolean = true

    override fun branchChanged(quality: Double) {
        val normalized = quality.coerceIn(0.0, 1.0)
        val amplitude = (150.0 - normalized * 82.0).toInt().coerceIn(48, 170)
        vibrate(durationMs = 16, amplitude = amplitude)
    }

    override fun commit() {
        vibrate(durationMs = 24, amplitude = 178)
        toneStart(ToneGenerator.TONE_PROP_BEEP, 55)
    }

    override fun gem() {
        vibrate(durationMs = 18, amplitude = 112)
        toneStart(ToneGenerator.TONE_PROP_ACK, 65)
    }

    override fun success() {
        vibrate(durationMs = 16, amplitude = 88)
        toneStart(ToneGenerator.TONE_PROP_PROMPT, 70)
    }

    override fun failure() {
        if (hapticsEnabled) {
            val waveform = longArrayOf(0L, 34L, 38L, 54L)
            val amplitudes = intArrayOf(0, 235, 0, 255)
            vibrator?.vibrate(VibrationEffect.createWaveform(waveform, amplitudes, -1))
        }
        toneStart(ToneGenerator.TONE_PROP_NACK, 140)
    }

    override fun close() {
        tone.release()
        vibrator?.cancel()
    }

    private fun vibrate(durationMs: Long, amplitude: Int) {
        if (!hapticsEnabled) return
        vibrator?.vibrate(VibrationEffect.createOneShot(durationMs, amplitude))
    }

    private fun toneStart(toneType: Int, durationMs: Int) {
        if (!soundEnabled) return
        tone.startTone(toneType, durationMs)
    }
}