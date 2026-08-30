import Foundation

enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case english = "en"
    case vietnamese = "vi"
    case japanese = "ja"
    case simplifiedChinese = "zh-Hans"

    var id: String { rawValue }
    var localeIdentifier: String { rawValue }

    static var systemDefault: AppLanguage {
        let tag = Locale.current.identifier.lowercased()
        if tag.hasPrefix("vi") { return .vietnamese }
        if tag.hasPrefix("ja") { return .japanese }
        if tag.hasPrefix("zh") { return .simplifiedChinese }
        return .english
    }

    var shortLabel: String {
        switch self {
        case .english: "EN"
        case .vietnamese: "VI"
        case .japanese: "JA"
        case .simplifiedChinese: "中文"
        }
    }

    var displayName: String {
        switch self {
        case .english: "English"
        case .vietnamese: "Tiếng Việt"
        case .japanese: "日本語"
        case .simplifiedChinese: "简体中文"
        }
    }

    func text(_ key: String) -> String {
        guard let path = Bundle.main.path(forResource: rawValue, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return key
        }
        return bundle.localizedString(forKey: key, value: nil, table: nil)
    }
}
