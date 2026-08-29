import SwiftUI

enum GameSkin: String, CaseIterable, Identifiable, Codable, Sendable {
    case classic
    case nebula
    case aurora
    case solar
    case obsidian
    case frozenQuartz

    var id: String { rawValue }

    var title: String {
        switch self {
        case .classic: "Classic"
        case .nebula: "Nebula"
        case .aurora: "Aurora"
        case .solar: "Solar"
        case .obsidian: "Obsidian"
        case .frozenQuartz: "Frozen Quartz"
        }
    }

    var subtitle: String {
        switch self {
        case .classic: "Kính nguyên bản"
        case .nebula: "Tím vũ trụ"
        case .aurora: "Lục lam cực quang"
        case .solar: "Vàng cam mặt trời"
        case .obsidian: "Đen chrome"
        case .frozenQuartz: "Lam băng"
        }
    }

    var requiresPlus: Bool { self != .classic }

    var palette: SkinPalette {
        switch self {
        case .classic:
            SkinPalette(backgroundTop: Color(red: 0.03, green: 0.06, blue: 0.13), backgroundBottom: .black, primary: .cyan, secondary: .purple, safe: .green, danger: .red)
        case .nebula:
            SkinPalette(backgroundTop: Color(red: 0.10, green: 0.03, blue: 0.19), backgroundBottom: Color(red: 0.02, green: 0.01, blue: 0.08), primary: Color(red: 0.30, green: 0.80, blue: 1), secondary: Color(red: 0.88, green: 0.35, blue: 1), safe: Color(red: 0.30, green: 1, blue: 0.62), danger: Color(red: 1, green: 0.30, blue: 0.42))
        case .aurora:
            SkinPalette(backgroundTop: Color(red: 0.00, green: 0.12, blue: 0.14), backgroundBottom: Color(red: 0.01, green: 0.04, blue: 0.07), primary: Color(red: 0.20, green: 0.95, blue: 1), secondary: Color(red: 0.22, green: 1, blue: 0.65), safe: Color(red: 0.28, green: 1, blue: 0.53), danger: Color(red: 1, green: 0.30, blue: 0.30))
        case .solar:
            SkinPalette(backgroundTop: Color(red: 0.16, green: 0.07, blue: 0.01), backgroundBottom: Color(red: 0.04, green: 0.02, blue: 0.01), primary: Color(red: 1, green: 0.75, blue: 0.26), secondary: Color(red: 1, green: 0.38, blue: 0.16), safe: Color(red: 0.45, green: 1, blue: 0.45), danger: Color(red: 1, green: 0.28, blue: 0.18))
        case .obsidian:
            SkinPalette(backgroundTop: Color(red: 0.05, green: 0.05, blue: 0.07), backgroundBottom: .black, primary: .white, secondary: Color(red: 0.52, green: 0.58, blue: 0.68), safe: Color(red: 0.25, green: 1, blue: 0.57), danger: Color(red: 1, green: 0.25, blue: 0.24))
        case .frozenQuartz:
            SkinPalette(backgroundTop: Color(red: 0.02, green: 0.10, blue: 0.20), backgroundBottom: Color(red: 0.01, green: 0.03, blue: 0.09), primary: Color(red: 0.42, green: 0.88, blue: 1), secondary: Color(red: 0.62, green: 0.70, blue: 1), safe: Color(red: 0.34, green: 1, blue: 0.72), danger: Color(red: 1, green: 0.34, blue: 0.38))
        }
    }
}

struct SkinPalette: Sendable {
    let backgroundTop: Color
    let backgroundBottom: Color
    let primary: Color
    let secondary: Color
    let safe: Color
    let danger: Color
}
