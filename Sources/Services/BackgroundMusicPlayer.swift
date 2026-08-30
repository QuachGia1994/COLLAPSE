import AVFAudio
import Foundation

/// Owns the single foreground background-music player for the iOS app,
/// mirroring the Android `BackgroundMusicPlayer` behavior: looping track,
/// lifecycle pause/resume, and lower volume in Power Save Mode.
@MainActor
final class BackgroundMusicPlayer {
    private var player: AVAudioPlayer?
    var isEnabled = true {
        didSet {
            guard !isEnabled else { return }
            player?.pause()
        }
    }

    func play() {
        guard isEnabled else { return }
        let audioPlayer = player ?? createPlayer()
        guard let audioPlayer else { return }
        player = audioPlayer
        refreshVolume()
        if !audioPlayer.isPlaying {
            audioPlayer.play()
        }
    }

    func pause() {
        player?.pause()
    }

    private func refreshVolume() {
        let volume = ProcessInfo.processInfo.isLowPowerModeEnabled ? Self.lowPowerVolume : Self.normalVolume
        player?.volume = volume
    }

    private func createPlayer() -> AVAudioPlayer? {
        guard let url = Bundle.main.url(forResource: "collapse_arcade_vibe", withExtension: "mp3") else {
            return nil
        }
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, options: [.mixWithOthers])
        try? session.setActive(true)
        guard let audioPlayer = try? AVAudioPlayer(contentsOf: url) else { return nil }
        audioPlayer.numberOfLoops = -1
        return audioPlayer
    }

    private static let normalVolume: Float = 0.18
    private static let lowPowerVolume: Float = 0.10
}
