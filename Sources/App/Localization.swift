import SwiftUI

struct AppBundleKey: EnvironmentKey {
    static let defaultValue: Bundle = .main
}

extension EnvironmentValues {
    var appBundle: Bundle {
        get { self[AppBundleKey.self] }
        set { self[AppBundleKey.self] = newValue }
    }
}
