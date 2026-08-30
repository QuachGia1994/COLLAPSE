import Observation
import StoreKit

enum PlusStoreError: Error, Equatable, Sendable {
    case productsUnavailable
    case verificationFailed
    case purchaseFailed
    case restoreFailed
    case unknownPurchaseResult

    var message: String {
        switch self {
        case .productsUnavailable: "Chưa tải được gói Plus."
        case .verificationFailed: "Không xác minh được giao dịch Plus."
        case .purchaseFailed: "Không thể hoàn tất giao dịch Plus."
        case .restoreFailed: "Không thể khôi phục giao dịch."
        case .unknownPurchaseResult: "App Store trả về trạng thái giao dịch chưa hỗ trợ."
        }
    }
}

@MainActor
@Observable
final class EntitlementStore {
    static let weeklyProductID = "collapse.plus.weekly"
    static let monthlyProductID = "collapse.plus.monthly"
    static let plusProductIDs = [weeklyProductID, monthlyProductID]

    private(set) var isPlusUnlocked = false
    private(set) var activeProductID: String?
    private(set) var products: [Product] = []
    private(set) var isLoadingProducts = false
    private(set) var isPurchasing = false
    private(set) var errorMessage: String?
    @ObservationIgnored private var transactionTask: Task<Void, Never>?

    init() {
        transactionTask = Task { [weak self] in
            for await result in Transaction.updates {
                guard !Task.isCancelled else { return }
                guard let self else { return }
                await self.handleTransactionUpdate(result)
            }
        }
        Task { [weak self] in
            await self?.refresh()
        }
    }

    func refresh() async {
        isLoadingProducts = true
        defer { isLoadingProducts = false }
        do {
            products = try await loadProducts()
            try await refreshEntitlements()
            errorMessage = nil
        } catch let error as PlusStoreError {
            errorMessage = error.message
        } catch {
            errorMessage = PlusStoreError.productsUnavailable.message
        }
    }

    func purchase(_ product: Product) async {
        guard Self.plusProductIDs.contains(product.id) else { return }
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            let result = try await product.purchase()
            try await handlePurchaseResult(result)
        } catch let error as PlusStoreError {
            errorMessage = error.message
        } catch {
            errorMessage = PlusStoreError.purchaseFailed.message
        }
    }

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            try await refreshEntitlements()
            errorMessage = nil
        } catch let error as PlusStoreError {
            errorMessage = error.message
        } catch {
            errorMessage = PlusStoreError.restoreFailed.message
        }
    }

    private func loadProducts() async throws -> [Product] {
        let loaded = try await Product.products(for: Self.plusProductIDs)
        guard !loaded.isEmpty else { throw PlusStoreError.productsUnavailable }
        return loaded.sorted { productOrder($0.id) < productOrder($1.id) }
    }

    private func productOrder(_ productID: String) -> Int {
        Self.plusProductIDs.firstIndex(of: productID) ?? Self.plusProductIDs.count
    }

    private func handlePurchaseResult(_ result: Product.PurchaseResult) async throws {
        switch result {
        case .success(let verification):
            let transaction = try verifiedTransaction(verification)
            await transaction.finish()
            try await refreshEntitlements()
            errorMessage = nil
        case .pending:
            errorMessage = "Giao dịch đang chờ App Store xác nhận."
        case .userCancelled:
            errorMessage = nil
        @unknown default:
            throw PlusStoreError.unknownPurchaseResult
        }
    }

    private func refreshEntitlements() async throws {
        var currentProductID: String?
        for await result in Transaction.currentEntitlements {
            switch result {
            case .verified(let transaction):
                guard isActivePlus(transaction) else { continue }
                currentProductID = transaction.productID
            case .unverified(let transaction, _):
                guard Self.plusProductIDs.contains(transaction.productID) else { continue }
                throw PlusStoreError.verificationFailed
            }
        }
        activeProductID = currentProductID
        isPlusUnlocked = currentProductID != nil
    }

    private func handleTransactionUpdate(_ result: VerificationResult<Transaction>) async {
        do {
            let transaction = try verifiedTransaction(result)
            guard Self.plusProductIDs.contains(transaction.productID) else { return }
            await transaction.finish()
            try await refreshEntitlements()
            errorMessage = nil
        } catch let error as PlusStoreError {
            errorMessage = error.message
        } catch {
            errorMessage = PlusStoreError.verificationFailed.message
        }
    }

    private func verifiedTransaction(_ result: VerificationResult<Transaction>) throws -> Transaction {
        switch result {
        case .verified(let transaction):
            return transaction
        case .unverified(_, _):
            throw PlusStoreError.verificationFailed
        }
    }

    private func isActivePlus(_ transaction: Transaction) -> Bool {
        guard Self.plusProductIDs.contains(transaction.productID) else { return false }
        guard transaction.revocationDate == nil else { return false }
        guard let expirationDate = transaction.expirationDate else { return true }
        return expirationDate > .now
    }
}