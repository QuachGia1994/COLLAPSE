import UIKit

struct HapticsClient: Sendable {
    let selection: @MainActor @Sendable () -> Void
    let commit: @MainActor @Sendable () -> Void
    let success: @MainActor @Sendable () -> Void
    let failure: @MainActor @Sendable () -> Void

    static let live = HapticsClient(
        selection: {
            UISelectionFeedbackGenerator().selectionChanged()
        },
        commit: {
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.75)
        },
        success: {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        },
        failure: {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    )

    static let silent = HapticsClient(selection: {}, commit: {}, success: {}, failure: {})
}
