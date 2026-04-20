import SwiftUI

struct SettingsView: View {
    @AppStorage("useMetricUnits") private var useMetricUnits: Bool = true
    @AppStorage("displayMode") private var displayMode: Int = 0 // 0: System, 1: Light, 2: Dark
    @AppStorage("useMonospacedFont") private var useMonospacedFont: Bool = false
    @AppStorage("preventScreenLock") private var preventScreenLock: Bool = true
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Units")) {
                    Picker("Units", selection: $useMetricUnits) {
                        Text("Metric").tag(true)
                        Text("Imperial").tag(false)
                    }
                    .pickerStyle(.segmented)
                    Text(useMetricUnits
                        ? "Speed in km/h, distance in km, temperature in °C"
                        : "Speed in mph, distance in miles, temperature in °F")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text("Appearance")) {
                    Picker("Display Mode", selection: $displayMode) {
                        Text("System").tag(0)
                        Text("Light").tag(1)
                        Text("Dark").tag(2)
                    }
                    .pickerStyle(.segmented)
                    
                    Toggle(isOn: $useMonospacedFont) {
                        Text("Use Fixed-Width Font")
                    }
                    
                    Toggle(isOn: $preventScreenLock) {
                        Text("Prevent Screen Lock")
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
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
