import AVFAudio
import CoreHaptics
import Foundation
import Observation

enum SensoryError: Error, Equatable, Sendable {
    case audioSetupFailed
    case hapticSetupFailed
    case hapticParameterUpdateFailed
    case hapticStopFailed
    case hapticPlaybackFailed
}

struct SensoryClient: Sendable {
    let beginGuidance: @MainActor @Sendable (Double) -> Void
    let updateGuidance: @MainActor @Sendable (Double) -> Void
    let stopGuidance: @MainActor @Sendable () -> Void
    let commit: @MainActor @Sendable () -> Void
    let gem: @MainActor @Sendable () -> Void
    let success: @MainActor @Sendable () -> Void
    let failure: @MainActor @Sendable () -> Void

    static let silent = SensoryClient(
        beginGuidance: { _ in },
        updateGuidance: { _ in },
        stopGuidance: {},
        commit: {},
        gem: {},
        success: {},
        failure: {}
    )
}

@MainActor
@Observable
final class SensoryEngine {
    @ObservationIgnored private let audioEngine = AVAudioEngine()
    @ObservationIgnored private let guidanceNode = AVAudioPlayerNode()
    @ObservationIgnored private let eventNode = AVAudioPlayerNode()
    @ObservationIgnored private let rateNode = AVAudioUnitVarispeed()
    @ObservationIgnored private var guidanceBuffer: AVAudioPCMBuffer?
    @ObservationIgnored private var hapticEngine: CHHapticEngine?
    @ObservationIgnored private var guidancePlayer: (any CHHapticAdvancedPatternPlayer)?

    private(set) var supportsHaptics = false
    private(set) var isAudioRunning = false
    private(set) var lastError: SensoryError?

    init() {
        configureAudioGraph()
        configureHaptics()
    }

    var client: SensoryClient {
        SensoryClient(
            beginGuidance: { [weak self] quality in self?.beginGuidance(quality: quality) },
            updateGuidance: { [weak self] quality in self?.updateGuidance(quality: quality) },
            stopGuidance: { [weak self] in self?.stopGuidance() },
            commit: { [weak self] in self?.playEvent(.commit) },
            gem: { [weak self] in self?.playEvent(.gem) },
            success: { [weak self] in self?.playEvent(.success) },
            failure: { [weak self] in self?.playEvent(.failure) }
        )
    }

    private func configureAudioGraph() {
        let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)
        audioEngine.attach(guidanceNode)
        audioEngine.attach(eventNode)
        audioEngine.attach(rateNode)
        audioEngine.connect(guidanceNode, to: rateNode, format: format)
        audioEngine.connect(rateNode, to: audioEngine.mainMixerNode, format: format)
        audioEngine.connect(eventNode, to: audioEngine.mainMixerNode, format: format)
        guidanceBuffer = Self.makeToneBuffer(frequency: 196, duration: 1, format: format)
    }

    private func configureHaptics() {
        supportsHaptics = CHHapticEngine.capabilitiesForHardware().supportsHaptics
        guard supportsHaptics else { return }
        do {
            let engine = try CHHapticEngine()
            engine.playsHapticsOnly = true
            hapticEngine = engine
        } catch {
            supportsHaptics = false
            lastError = .hapticSetupFailed
        }
    }

    private func beginGuidance(quality: Double) {
        startAudioIfNeeded()
        startGuidanceAudio()
        startGuidanceHaptic()
        updateGuidance(quality: quality)
    }

    private func updateGuidance(quality: Double) {
        let value = min(max(quality, 0), 1)
        rateNode.rate = Float(0.82 + value * 0.58)
        guidanceNode.volume = Float(0.020 + value * 0.018)
        guard let guidancePlayer else { return }
        do {
            try guidancePlayer.sendParameters(dynamicParameters(for: value), atTime: 0)
        } catch {
            lastError = .hapticParameterUpdateFailed
        }
    }

    private func dynamicParameters(for quality: Double) -> [CHHapticDynamicParameter] {
        let intensity = Float(0.68 - quality * 0.38)
        let sharpness = Float(-0.35 + quality * 1.20)
        return [
            CHHapticDynamicParameter(parameterID: .hapticIntensityControl, value: intensity, relativeTime: 0),
            CHHapticDynamicParameter(parameterID: .hapticSharpnessControl, value: sharpness, relativeTime: 0)
        ]
    }

    private func stopGuidance() {
        guidanceNode.stop()
        guard let guidancePlayer else { return }
        do {
            try guidancePlayer.stop(atTime: 0)
        } catch {
            lastError = .hapticStopFailed
        }
        self.guidancePlayer = nil
    }

    private func startGuidanceAudio() {
        guard let guidanceBuffer, !guidanceNode.isPlaying else { return }
        guidanceNode.scheduleBuffer(guidanceBuffer, at: nil, options: .loops)
        guidanceNode.play()
    }

    private func startGuidanceHaptic() {
        guard supportsHaptics, let hapticEngine else { return }
        do {
            try hapticEngine.start()
            let pattern = try CHHapticPattern(events: [guidanceHapticEvent], parameters: [])
            let player = try hapticEngine.makeAdvancedPlayer(with: pattern)
            guidancePlayer = player
            try player.start(atTime: 0)
        } catch {
            guidancePlayer = nil
            lastError = .hapticPlaybackFailed
        }
    }

    private var guidanceHapticEvent: CHHapticEvent {
        CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.55),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.20)
            ],
            relativeTime: 0,
            duration: 2
        )
    }

    private func playEvent(_ event: SensoryEvent) {
        stopGuidance()
        startAudioIfNeeded()
        playAudioEvent(event)
        playHapticEvent(event)
    }

    private func playAudioEvent(_ event: SensoryEvent) {
        let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)
        guard let buffer = Self.makeToneBuffer(frequency: event.frequency, duration: event.duration, format: format) else {
            lastError = .audioSetupFailed
            return
        }
        eventNode.stop()
        eventNode.scheduleBuffer(buffer)
        eventNode.volume = Float(event.volume)
        eventNode.play()
    }

    private func playHapticEvent(_ event: SensoryEvent) {
        guard supportsHaptics, let hapticEngine else { return }
        do {
            try hapticEngine.start()
            let pattern = try CHHapticPattern(events: [event.hapticEvent], parameters: [])
            let player = try hapticEngine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            lastError = .hapticPlaybackFailed
        }
    }

    private func startAudioIfNeeded() {
        guard !audioEngine.isRunning else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, options: [.mixWithOthers])
            try session.setActive(true)
            try audioEngine.start()
            isAudioRunning = true
        } catch {
            isAudioRunning = false
            lastError = .audioSetupFailed
        }
    }

    private static func makeToneBuffer(frequency: Double, duration: Double, format: AVAudioFormat?) -> AVAudioPCMBuffer? {
        guard let format, let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(format.sampleRate * duration)), let channel = buffer.floatChannelData?[0] else { return nil }
        buffer.frameLength = buffer.frameCapacity
        for frame in 0..<Int(buffer.frameLength) {
            let phase = 2 * Double.pi * frequency * Double(frame) / format.sampleRate
            channel[frame] = Float(sin(phase) * 0.18)
        }
        return buffer
    }
}

private enum SensoryEvent {
    case commit
    case gem
    case success
    case failure

    var frequency: Double {
        switch self {
        case .commit: 320
        case .gem: 980
        case .success: 720
        case .failure: 118
        }
    }

    var duration: Double {
        switch self {
        case .commit: 0.08
        case .gem: 0.07
        case .success: 0.11
        case .failure: 0.20
        }
    }

    var volume: Double {
        switch self {
        case .commit: 0.05
        case .gem: 0.075
        case .success: 0.07
        case .failure: 0.06
        }
    }

    var hapticEvent: CHHapticEvent {
        CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(hapticIntensity)),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: Float(hapticSharpness))
            ],
            relativeTime: 0
        )
    }

    private var hapticIntensity: Double {
        switch self {
        case .commit: 0.72
        case .gem: 0.44
        case .success: 0.52
        case .failure: 0.95
        }
    }

    private var hapticSharpness: Double {
        switch self {
        case .commit: 0.78
        case .gem: 1.0
        case .success: 0.92
        case .failure: 0.10
        }
    }
}