import Foundation
import Combine

@MainActor
final class LanguageManager: ObservableObject {

    struct Language: Identifiable {
        let id: String          // ISO 639-1 code or "system"
        let displayName: String // Always in the target language
    }

    static let supported: [Language] = [
        .init(id: "system", displayName: "System Default"),
        .init(id: "en",     displayName: "English"),
        .init(id: "fr",     displayName: "Français"),
        .init(id: "es",     displayName: "Español"),
        .init(id: "pl",     displayName: "Polski"),
    ]

    @Published private(set) var currentCode: String

    var currentBundle: Bundle {
        guard currentCode != "system", currentCode != "en" else { return .main }
        let path = Bundle.main.bundlePath + "/\(currentCode).lproj"
        return Bundle(path: path) ?? .main
    }

    init() {
        currentCode = UserDefaults.standard.string(forKey: "appLanguage") ?? "system"
    }

    func select(_ code: String) {
        UserDefaults.standard.set(code, forKey: "appLanguage")
        currentCode = code
    }
}
