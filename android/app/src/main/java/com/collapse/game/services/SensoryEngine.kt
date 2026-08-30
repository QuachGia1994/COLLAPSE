package com.collapse.game.services

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioTrack
import android.os.VibrationEffect
import android.os.Vibrator
import com.collapse.game.domain.SensoryClient
import kotlin.math.PI
import kotlin.math.sin

/**
 * Mirrors the iOS SensoryEngine feel within Android APIs:
 * - SFX: procedural sine tones with the same frequencies, durations and
 *   volumes as the iOS AVAudioEngine graph (196 Hz guidance loop with
 *   quality-driven volume/playback-rate, plus commit/gem/success/failure).
 * - Haptics: amplitudes follow the iOS Core Haptics intensity curves
 *   (commit 0.72, gem 0.44, success 0.52, failure 0.95, guidance
 *   0.68 - quality * 0.38) instead of a plain on/off switch.
 */
class SensoryEngine(context: Context) : SensoryClient, AutoCloseable {
    private val vibrator = context.getSystemService(Vibrator::class.java)
    var soundEnabled: Boolean = true
    var hapticsEnabled: Boolean = true

    private var guidanceTrack: AudioTrack? = null
    private var eventTrack: AudioTrack? = null

    override fun branchChanged(quality: Double) {
        val normalized = quality.coerceIn(0.0, 1.0)
        // iOS guidance haptic intensity: 0.68 - quality * 0.38
        val amplitude = ((GUIDE_INTENSITY_BASE - normalized * GUIDE_INTENSITY_SLOPE) * 255.0).toInt().coerceIn(40, 255)
        vibrate(durationMs = 16, amplitude = amplitude)
        updateGuidanceTone(normalized)
    }

    override fun commit() {
        stopGuidanceTone()
        vibrate(durationMs = 24, amplitude = (COMMIT_INTENSITY * 255).toInt())
        playTone(frequencyHz = 320.0, durationMs = 80, volume = 0.05f)
    }

    override fun gem() {
        stopGuidanceTone()
        vibrate(durationMs = 18, amplitude = (GEM_INTENSITY * 255).toInt())
        playTone(frequencyHz = 980.0, durationMs = 70, volume = 0.075f)
    }

    override fun success() {
        stopGuidanceTone()
        vibrate(durationMs = 16, amplitude = (SUCCESS_INTENSITY * 255).toInt())
        playTone(frequencyHz = 720.0, durationMs = 110, volume = 0.07f)
    }

    override fun failure() {
        stopGuidanceTone()
        // iOS failure: intensity 0.95, sharpness 0.10 -> one dull strong thud.
        if (hapticsEnabled) {
            vibrator?.vibrate(VibrationEffect.createOneShot(36, (FAILURE_INTENSITY * 255).toInt()))
        }
        playTone(frequencyHz = 118.0, durationMs = 200, volume = 0.06f)
    }

    override fun close() {
        guidanceTrack?.release()
        guidanceTrack = null
        eventTrack?.release()
        eventTrack = null
        vibrator?.cancel()
    }

    private fun vibrate(durationMs: Long, amplitude: Int) {
        if (!hapticsEnabled) return
        vibrator?.vibrate(VibrationEffect.createOneShot(durationMs, amplitude))
    }

    private fun updateGuidanceTone(quality: Double) {
        if (!soundEnabled) return
        val track = guidanceTrack ?: createGuidanceTrack()?.also { guidanceTrack = it } ?: return
        // iOS guidance node volume: 0.020 + quality * 0.018
        track.setVolume((GUIDE_VOLUME_BASE + quality * GUIDE_VOLUME_SLOPE).toFloat())
        // iOS Varispeed rate: 0.82 + quality * 0.58 (pitch shifts with quality)
        runCatching {
            track.playbackRate = (SAMPLE_RATE * (GUIDE_RATE_BASE + quality * GUIDE_RATE_SLOPE)).toInt()
        }
        if (track.playState != AudioTrack.PLAYSTATE_PLAYING) track.play()
    }

    private fun stopGuidanceTone() {
        guidanceTrack?.pause()
    }

    private fun createGuidanceTrack(): AudioTrack? {
        val frames = SAMPLE_RATE // one second of guidance tone, looped
        val pcm = sinePcm(frames, GUIDE_FREQUENCY)
        return buildStaticTrack(pcm)?.apply {
            setLoopPoints(0, frames, -1)
        }
    }

    private fun playTone(frequencyHz: Double, durationMs: Int, volume: Float) {
        if (!soundEnabled) return
        val frames = SAMPLE_RATE * durationMs / 1000
        val pcm = sinePcm(frames, frequencyHz)
        eventTrack?.release()
        eventTrack = buildStaticTrack(pcm)?.apply {
            setVolume(volume)
            play()
        }
    }

    private fun buildStaticTrack(pcm: ByteArray): AudioTrack? = runCatching {
        AudioTrack.Builder()
            .setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_MEDIA)
                    .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                    .build()
            )
            .setAudioFormat(
                AudioFormat.Builder()
                    .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                    .setSampleRate(SAMPLE_RATE)
                    .setChannelConfig(AudioFormat.CHANNEL_OUT_MONO)
                    .build()
            )
            .setBufferSizeInBytes(pcm.size)
            .setTransferMode(AudioTrack.MODE_STATIC)
            .build()
            .also { it.write(pcm, 0, pcm.size) }
    }.getOrNull()

    private fun sinePcm(frames: Int, frequencyHz: Double): ByteArray {
        val pcm = ByteArray(frames * 2)
        for (frame in 0 until frames) {
            val phase = 2.0 * PI * frequencyHz * frame / SAMPLE_RATE
            // iOS makeToneBuffer amplitude: sin(phase) * 0.18
            val sample = (sin(phase) * 0.18 * Short.MAX_VALUE.toInt()).toInt().toShort()
            pcm[frame * 2] = (sample.toInt() and 0xFF).toByte()
            pcm[frame * 2 + 1] = ((sample.toInt() shr 8) and 0xFF).toByte()
        }
        return pcm
    }

    private companion object {
        const val SAMPLE_RATE = 44_100
        const val GUIDE_FREQUENCY = 196.0
        const val GUIDE_VOLUME_BASE = 0.020
        const val GUIDE_VOLUME_SLOPE = 0.018
        const val GUIDE_RATE_BASE = 0.82
        const val GUIDE_RATE_SLOPE = 0.58
        const val GUIDE_INTENSITY_BASE = 0.68
        const val GUIDE_INTENSITY_SLOPE = 0.38
        const val COMMIT_INTENSITY = 0.72
        const val GEM_INTENSITY = 0.44
        const val SUCCESS_INTENSITY = 0.52
        const val FAILURE_INTENSITY = 0.95
    }
}
