import SwiftUI

@MainActor
struct PlusView: View {
    @Environment(EntitlementStore.self) private var entitlement
    @Environment(\.dismiss) private var dismiss

    private let benefits = [
        ("sparkles", "Toàn bộ skin Plus"),
        ("wand.and.stars", "Shader và hiệu ứng cao cấp"),
        ("waveform", "Haptics và soundscape Plus"),
        ("play.rectangle.on.rectangle", "Replay và Ghost ở giai đoạn kế tiếp"),
        ("heart", "Hỗ trợ phát triển COLLAPSE")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    plusOrb

                    VStack(spacing: 5) {
                        Text("COLLAPSE PLUS")
                            .font(.title.weight(.semibold))
                            .tracking(3)
                        Text("Mua một lần. Gameplay không mạnh hơn.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

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
                    .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 22, style: .continuous))

                    if entitlement.isPlusUnlocked {
                        Label("PLUS ĐÃ MỞ", systemImage: "checkmark.seal.fill")
                            .font(.headline)
                            .foregroundStyle(.green)
                    } else {
                        Button {
                            Task { await entitlement.purchasePlus() }
                        } label: {
                            HStack {
                                Text("MỞ PLUS")
                                Spacer()
                                Text(entitlement.displayPrice)
                            }
                            .font(.headline)
                            .padding(.horizontal, 4)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.yellow)
                        .controlSize(.large)
                        .disabled(entitlement.plusProduct == nil || entitlement.isLoading)

                        Button("Khôi phục giao dịch") {
                            Task { await entitlement.restorePurchases() }
                        }
                        .font(.footnote)

                        if let errorMessage = entitlement.errorMessage {
                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }

                    Text("Plus chỉ thay đổi trình bày và tính năng lưu/nhìn lại. Hazard, thời gian, điểm và độ sống sót giống hệt bản Free.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(22)
            }
            .background(Color.black.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Đóng") { dismiss() }
                }
            }
        }
        .task { await entitlement.refresh() }
    }

    private var plusOrb: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.white.opacity(0.82), .cyan.opacity(0.65), .purple.opacity(0.55), .clear],
                        center: .topLeading,
                        startRadius: 8,
                        endRadius: 130
                    )
                )
                .frame(width: 190, height: 190)
                .blur(radius: 0.2)
            Circle()
                .stroke(
                    AngularGradient(colors: [.cyan, .blue, .purple, .pink, .cyan], center: .center),
                    lineWidth: 3
                )
                .frame(width: 210, height: 210)
            Image(systemName: "plus")
                .font(.system(size: 42, weight: .light))
                .foregroundStyle(.white)
        }
        .padding(.top, 18)
    }
}
