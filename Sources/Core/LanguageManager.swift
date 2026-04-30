import Foundation
import Combine

@MainActor
final class LanguageManager: ObservableObject {

    struct Language: Identifiable {
        let id: String          // ISO 639-1 code or "system"
        let displayName: String // Always in the target language
    }

    static let supported: [Language] = [
        .init(id: "system", displayName: String(localized: "System Default")),
        .init(id: "en",     displayName: "English"),
        .init(id: "fr",     displayName: "Français"),
        .init(id: "es",     displayName: "Español"),
        .init(id: "pl",     displayName: "Polski"),
    ]

    @Published private(set) var currentCode: String

    init() {
        let saved = UserDefaults.standard.string(forKey: "appLanguage") ?? "system"
        currentCode = saved
        object_setClass(Bundle.main, LanguageBundleOverride.self)
        Self.activate(saved)
    }

    func select(_ code: String) {
        UserDefaults.standard.set(code, forKey: "appLanguage")
        Self.activate(code)
        currentCode = code
    }

    private static func activate(_ code: String) {
        guard code != "system",
              let path = Bundle.main.path(forResource: code, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            LanguageBundleOverride.override = nil
            return
        }
        LanguageBundleOverride.override = bundle
    }
}

// Intercepts all Bundle.main string lookups and redirects to the chosen lproj bundle.
private final class LanguageBundleOverride: Bundle, @unchecked Sendable {
    nonisolated(unsafe) static var override: Bundle?

    override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        guard let bundle = Self.override else {
            return super.localizedString(forKey: key, value: value, table: tableName)
        }
        return bundle.localizedString(forKey: key, value: value, table: tableName)
    }
}
