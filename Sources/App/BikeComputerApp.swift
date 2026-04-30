import SwiftUI
import SwiftData

@main
struct BikeComputerApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Activity.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    @AppStorage("displayMode") private var displayMode: Int = 0
    @StateObject private var languageManager = LanguageManager()

    private var selectedColorScheme: ColorScheme? {
        switch displayMode {
        case 1: return .light
        case 2: return .dark
        default: return nil
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .id(languageManager.currentCode)
                .environmentObject(languageManager)
                .preferredColorScheme(selectedColorScheme)
        }
        .modelContainer(sharedModelContainer)
    }
}
