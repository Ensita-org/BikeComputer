import SwiftUI

struct SettingsView: View {
    @AppStorage("useMetricUnits") private var useMetricUnits: Bool = true
    @AppStorage("displayMode") private var displayMode: Int = 0
    @AppStorage("useMonospacedFont") private var useMonospacedFont: Bool = false
    @AppStorage("preventScreenLock") private var preventScreenLock: Bool = true
    @AppStorage("showWeather") private var showWeather: Bool = true
    @AppStorage("showMap") private var showMap: Bool = true
    @EnvironmentObject private var languageManager: LanguageManager
    @Environment(\.appBundle) private var bundle
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Units", bundle: bundle)) {
                    Picker(selection: $useMetricUnits) {
                        Text("Metric", bundle: bundle).tag(true)
                        Text("Imperial", bundle: bundle).tag(false)
                    } label: {
                        Text("Units", bundle: bundle)
                    }
                    .pickerStyle(.segmented)
                    Text(useMetricUnits
                        ? "Speed in km/h, distance in km, temperature in °C"
                        : "Speed in mph, distance in miles, temperature in °F",
                         bundle: bundle)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }

                Section(header: Text("Privacy", bundle: bundle)) {
                    Toggle(isOn: $showWeather) {
                        Text("Show Weather Widget", bundle: bundle)
                    }
                    Text(showWeather
                        ? "Current weather is fetched from Open-Meteo using your location."
                        : "No weather requests are sent. The widget is hidden on the dashboard.",
                         bundle: bundle)
                        .font(.footnote)
                        .foregroundColor(.secondary)

                    Toggle(isOn: $showMap) {
                        Text("Show Map on Ride Details", bundle: bundle)
                    }
                    Text(showMap
                        ? "Route is drawn over Apple Maps. Opening a ride sends a tile request to Apple."
                        : "Route is drawn on a plain background. No map tiles are fetched from Apple.",
                         bundle: bundle)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }

                Section(header: Text("Language", bundle: bundle)) {
                    Picker(selection: Binding(
                        get: { languageManager.currentCode },
                        set: { languageManager.select($0) }
                    )) {
                        ForEach(LanguageManager.supported) { language in
                            Text(language.displayName).tag(language.id)
                        }
                    } label: {
                        Text("Language", bundle: bundle)
                    }
                }

                Section(header: Text("Appearance", bundle: bundle)) {
                    Picker(selection: $displayMode) {
                        Text("System", bundle: bundle).tag(0)
                        Text("Light", bundle: bundle).tag(1)
                        Text("Dark", bundle: bundle).tag(2)
                    } label: {
                        Text("Display Mode", bundle: bundle)
                    }
                    .pickerStyle(.segmented)

                    Toggle(isOn: $useMonospacedFont) {
                        Text("Use Fixed-Width Font", bundle: bundle)
                    }

                    Toggle(isOn: $preventScreenLock) {
                        Text("Prevent Screen Lock", bundle: bundle)
                    }
                }
            }
            .navigationTitle(bundle.localizedString(forKey: "Settings", value: nil, table: nil))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(bundle.localizedString(forKey: "Done", value: nil, table: nil)) {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
