import Foundation
import Observation
import StoreKit

@MainActor
@Observable
final class EntitlementStore {
    static let plusProductID = "collapse.plus.lifetime"

    private(set) var plusProduct: Product?
    private(set) var isPlusUnlocked = false
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private var transactionTask: Task<Void, Never>?

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

    var displayPrice: String {
        plusProduct?.displayPrice ?? "—"
    }

    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        do {
            plusProduct = try await Product.products(for: [Self.plusProductID]).first
            await refreshEntitlements()
            errorMessage = plusProduct == nil && !isPlusUnlocked ? "Plus chưa được cấu hình trên App Store." : nil
        } catch {
            errorMessage = "Plus hiện không khả dụng."
        }
    }

    func purchasePlus() async {
        guard let plusProduct else {
            errorMessage = "Plus chưa được cấu hình trên App Store."
            return
        }

        do {
            let result = try await plusProduct.purchase()
            switch result {
            case .success(let verification):
                guard case .verified(let transaction) = verification else {
                    errorMessage = "Không thể xác minh giao dịch."
                    return
                }
                await transaction.finish()
                await refreshEntitlements()
            case .pending:
                errorMessage = "Giao dịch đang chờ phê duyệt."
            case .userCancelled:
                errorMessage = nil
            @unknown default:
                errorMessage = "App Store trả về trạng thái chưa xác định."
            }
        } catch {
            errorMessage = "Không thể hoàn tất giao dịch."
        }
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
