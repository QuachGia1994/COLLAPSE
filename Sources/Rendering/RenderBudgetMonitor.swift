import Foundation

@MainActor
final class RenderBudgetMonitor {
    static let targetMilliseconds = 8.3

    private var lastTimestamp: TimeInterval?
    private(set) var peakMilliseconds = 0.0
    private(set) var averageMilliseconds = 0.0
    private(set) var sampleCount = 0
    private(set) var overBudgetFrames = 0

    func record(timestamp: TimeInterval) {
        defer { lastTimestamp = timestamp }
        guard let lastTimestamp else { return }
        let milliseconds = max(0, timestamp - lastTimestamp) * 1_000
        peakMilliseconds = max(peakMilliseconds, milliseconds)
        sampleCount += 1
        averageMilliseconds += (milliseconds - averageMilliseconds) / Double(sampleCount)
        guard milliseconds > Self.targetMilliseconds else { return }
        overBudgetFrames += 1
    }

    func reset() {
        lastTimestamp = nil
        peakMilliseconds = 0
        averageMilliseconds = 0
        sampleCount = 0
        overBudgetFrames = 0
    }
}