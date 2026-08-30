import StoreKit
import SwiftUI

@MainActor
struct PlusView: View {
    @Environment(EntitlementStore.self) private var entitlement
    @Environment(\.dismiss) private var dismiss

    private let benefits = [
        ("rectangle.slash", "Tắt quảng cáo"),
        ("sparkles", "Theme và pulse Plus riêng"),
        ("bolt.horizontal.circle", "Vào sớm level và mode mới"),
        ("waveform", "Soundscape và haptic Plus"),
        ("shield.checkered", "Không tăng điểm hay lợi thế sống sót")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    plusOrb
                    titleBlock
                    benefitsCard
                    purchaseSection
                    fairnessNote
                }
                .padding(22)
            }
            .background(background)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Đóng") { dismiss() }
                }
            }
        }
        .task { await entitlement.refresh() }
    }

    private var titleBlock: some View {
        VStack(spacing: 5) {
            Text("COLLAPSE PLUS")
                .font(.title.weight(.semibold))
                .tracking(3)
            Text("Đăng ký tuần hoặc tháng. Hủy bất kỳ lúc nào trong App Store.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var benefitsCard: some View {
        VStack(spacing: 13) {
            ForEach(benefits.indices, id: \.self) { index in
                let benefit = benefits[index]
                HStack(spacing: 13) {
                    Image(systemName: benefit.0)
                        .frame(width: 24)
                        .foregroundStyle(.yellow)
                    Text(benefit.1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .font(.subheadline)
            }
        }
        .padding(18)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.10), lineWidth: 1)
        }
    }

    @ViewBuilder
    private var purchaseSection: some View {
        if entitlement.isPlusUnlocked {
            Label(activePlanLabel, systemImage: "checkmark.seal.fill")
                .font(.headline)
                .foregroundStyle(.green)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.thinMaterial, in: Capsule())
        } else if entitlement.isLoadingProducts {
            ProgressView("Đang tải gói Plus…")
                .padding(16)
                .background(.thinMaterial, in: Capsule())
        } else {
            VStack(spacing: 12) {
                ForEach(entitlement.products, id: \.id) { product in
                    purchaseButton(product)
                }

                Button("Khôi phục giao dịch") {
                    Task { await entitlement.restorePurchases() }
                }
                .font(.footnote)
                .disabled(entitlement.isPurchasing)

                if entitlement.products.isEmpty {
                    Button("Tải lại gói Plus") {
                        Task { await entitlement.refresh() }
                    }
                    .font(.footnote)
                }
            }
        }

        if let errorMessage = entitlement.errorMessage {
            Text(errorMessage)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private func purchaseButton(_ product: Product) -> some View {
        Button {
            Task { await entitlement.purchase(product) }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(planName(product.id))
                        .font(.headline)
                    Text(product.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(product.displayPrice)
                    .font(.headline.monospacedDigit())
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(.white.opacity(0.12), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .disabled(entitlement.isPurchasing)
    }

    private var fairnessNote: some View {
        Text("Plus chỉ thay đổi quảng cáo, theme/pulse và quyền truy cập sớm. Hazard, thời gian quyết định, điểm và khả năng sống sót giống hệt Free.")
            .font(.caption)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
    }

    private var plusOrb: some View {
        ZStack {
            Circle()
                .fill(.regularMaterial)
                .frame(width: 190, height: 190)
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.white.opacity(0.74), .cyan.opacity(0.36), .purple.opacity(0.28), .clear],
                        center: .topLeading,
                        startRadius: 8,
                        endRadius: 126
                    )
                )
                .frame(width: 184, height: 184)
            Circle()
                .stroke(.white.opacity(0.20), lineWidth: 1)
                .frame(width: 204, height: 204)
            CollapseLogoSymbol(tint: .yellow)
                .frame(width: 92, height: 92)
            Image(systemName: "plus.circle.fill")
                .font(.title2)
                .foregroundStyle(.yellow)
                .offset(x: 58, y: 58)
        }
        .padding(.top, 18)
    }

    private var background: some View {
        LinearGradient(colors: [.black, Color(red: 0.05, green: 0.05, blue: 0.12)], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
    }

    private var activePlanLabel: String {
        guard let activeProductID = entitlement.activeProductID else { return "PLUS ĐANG HOẠT ĐỘNG" }
        return "PLUS \(planName(activeProductID).uppercased()) ĐANG HOẠT ĐỘNG"
    }

    private func planName(_ productID: String) -> String {
        productID == EntitlementStore.weeklyProductID ? "Hàng tuần" : "Hàng tháng"
    }
}