import SwiftUI

struct StartupView: View {
    @Environment(PlayerProfile.self) private var profile

    var body: some View {
        ZStack {
            RadialGradient(
                colors: [Color(red: 0.03, green: 0.08, blue: 0.14), .black],
                center: .center,
                startRadius: 20,
                endRadius: 520
            )
            .ignoresSafeArea()

            VStack(spacing: 22) {
                CollapseLogoSymbol(tint: .cyan)
                    .frame(width: 112, height: 112)
                    .padding(24)
                    .background(.thinMaterial, in: Circle())
                    .overlay { Circle().stroke(.cyan.opacity(0.24), lineWidth: 1.5) }

                VStack(spacing: 7) {
                    Text("COLLAPSE")
                        .font(.system(size: 32, weight: .light, design: .rounded))
                        .tracking(8)
                    Text(profile.selectedLanguage.text("brand.subtitle"))
                        .font(.caption.weight(.semibold))
                        .tracking(3)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("COLLAPSE")
    }
}
