import Foundation

enum GameMode: String, CaseIterable, Identifiable, Sendable {
    case classic
    case rush
    case precision
    case daily
    case zen

    var id: String { rawValue }

    var title: String {
        switch self {
        case .classic: "CLASSIC"
        case .rush: "RUSH"
        case .precision: "PRECISION"
        case .daily: "DAILY"
        case .zen: "ZEN"
        }
    }

    var subtitle: String {
        switch self {
        case .classic: "Nhịp cân bằng nguyên bản."
        case .rush: "Quyết định nhanh, chuyển động nhanh."
        case .precision: "Chỉ một lần đổi nhánh mỗi round."
        case .daily: "Một timeline cố định cho mỗi ngày."
        case .zen: "Practice chậm, va chạm không kết thúc run."
        }
    }

    var choiceBase: Double {
        switch self {
        case .classic: 1.45
        case .rush: 1.05
        case .precision: 1.24
        case .daily: 1.28
        case .zen: 2.00
        }
    }

    var choiceFloor: Double {
        switch self {
        case .classic: 0.72
        case .rush: 0.52
        case .precision: 0.58
        case .daily: 0.62
        case .zen: 1.20
        }
    }

    var choiceDecay: Double {
        switch self {
        case .classic: 0.045
        case .rush: 0.032
        case .precision: 0.038
        case .daily: 0.040
        case .zen: 0.025
        }
    }

    var travelBase: Double {
        switch self {
        case .classic: 0.90
        case .rush: 0.68
        case .precision: 0.82
        case .daily: 0.84
        case .zen: 1.08
        }
    }

    var travelFloor: Double {
        switch self {
        case .classic: 0.62
        case .rush: 0.46
        case .precision: 0.56
        case .daily: 0.56
        case .zen: 0.82
        }
    }

    var travelDecay: Double {
        switch self {
        case .classic: 0.012
        case .rush: 0.010
        case .precision: 0.010
        case .daily: 0.011
        case .zen: 0.006
        }
    }

    var hazardRadiusMultiplier: Double {
        switch self {
        case .precision: 1.28
        case .daily: 1.10
        case .zen: 0.90
        case .classic, .rush: 1.0
        }
    }

    var maxSwitchesPerRound: Int? {
        self == .precision ? 1 : nil
    }

    var collisionEndsRun: Bool { self != .zen }
    var isCompetitive: Bool { self != .zen }

    func seed(on date: Date = .now, calendar: Calendar = .current) -> UInt64 {
        guard self == .daily else { return 0xC011A953 }
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let year = components.year ?? 2000
        let month = components.month ?? 1
        let day = components.day ?? 1
        let dayNumber = UInt64(year * 10_000 + month * 100 + day)
        return dayNumber ^ 0xD41C0A53
    }
}
