import Observation
import StoreKit

@MainActor
@Observable
final class EntitlementStore {
    static let plusProductID = "collapse.plus.lifetime"

    private(set) var isPlusUnlocked = false
    private(set) var errorMessage: String?
    @ObservationIgnored private var transactionTask: Task<Void, Never>?

    init() {
        transactionTask = Task { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                guard case .verified(let transaction) = result else { continue }
                await transaction.finish()
                await self.refreshEntitlements()
            }
        }
        Task { await refresh() }
    }

    func refresh() async {
        await refreshEntitlements()
        errorMessage = nil
    }

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            errorMessage = nil
        } catch {
            errorMessage = "Không thể khôi phục giao dịch."
        }
    }

    private func refreshEntitlements() async {
        var unlocked = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if transaction.productID == Self.plusProductID, transaction.revocationDate == nil {
                unlocked = true
                break
            }
        }
        isPlusUnlocked = unlocked
    }
}
