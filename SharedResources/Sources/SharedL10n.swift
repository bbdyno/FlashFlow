import Foundation

public enum SharedL10n {
    public static func localized(_ key: String, fallback: String = "") -> String {
        Bundle.module.localizedString(forKey: key, value: fallback, table: "Localizable")
    }
}
