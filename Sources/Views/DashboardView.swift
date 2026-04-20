import SwiftUI
import CoreLocation
import SwiftData

struct DashboardView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var weatherManager = WeatherManager()
    @StateObject private var activityManager: ActivityManager
    @Environment(\.modelContext) private var modelContext
    
    @AppStorage("useMetricUnits") private var useMetricUnits: Bool = true
    @AppStorage("useMonospacedFont") private var useMonospacedFont: Bool = false
    @State private var showingSettings = false
    
    init() {
        let locManager = LocationManager()
        _locationManager = StateObject(wrappedValue: locManager)
        _activityManager = StateObject(wrappedValue: ActivityManager(locationManager: locManager))
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Weather Header
            if let weather = weatherManager.currentWeather {
                HStack {
                    Image(systemName: weather.iconName)
                        .font(.title)
                    Text(useMetricUnits
                        ? "\(Int(weather.temperature))°C"
                        : "\(Int(weather.temperature * 9 / 5 + 32))°F")
                        .font(.title2)
                    Text(weather.condition)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(.thinMaterial)
                .cornerRadius(15)
            } else {
                Text("Loading Weather...")
                    .font(.caption)
                    .onAppear {
                        if let loc = locationManager.location {
                            Task {
                                await weatherManager.fetchWeather(for: loc)
                            }
                        }
                    }
                    .onChange(of: locationManager.location) { oldValue, newValue in
                        if let loc = newValue, weatherManager.currentWeather == nil {
                            Task {
                                await weatherManager.fetchWeather(for: loc)
                            }
                        }
                    }
            }

            // Elevation
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.right")
                        Text(formatElevation(activityManager.ascent))
                    }
                    .font(.title3)
                    Text("Ascent")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(formatElevation(activityManager.descent))
                        Image(systemName: "arrow.down.right")
                    }
                    .font(.title3)
                    Text("Descent")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)

            Spacer()
            
            // Speed
            VStack {
                Text("Speed")
                    .font(.headline)
                    .foregroundColor(.secondary)
                VStack(spacing: -20) {
                    Text(String(format: "%.1f", useMetricUnits ? (activityManager.currentSpeed * 3.6) : (activityManager.currentSpeed * 2.23693629)))
                        .font(.system(size: 180, weight: .bold, design: useMonospacedFont ? .monospaced : .rounded))
                        .monospacedDigit()
                        .minimumScaleFactor(0.4)
                        .lineLimit(1)
                        .padding(.horizontal)
                    Text(useMetricUnits ? "km/h" : "mph")
                        .font(.title)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Stats Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                StatBox(title: "Distance", value: {
                    let km = activityManager.distance / 1000
                    let miles = km * 0.621371
                    return String(format: useMetricUnits ? "%.2f km" : "%.2f mi", useMetricUnits ? km : miles)
                }())
                StatBox(title: "Avg Speed", value: {
                    let kph = activityManager.averageSpeed * 3.6
                    let mph = kph * 0.621371
                    return String(format: useMetricUnits ? "%.1f km/h" : "%.1f mph", useMetricUnits ? kph : mph)
                }())
                StatBox(title: "Duration", value: formatDuration(activityManager.elapsedTime))
                StatBox(title: "Altitude", value: "\(Int((locationManager.location?.altitude ?? 0))) m")
            }
            .padding()
            
            Spacer()
            
            // Controls
            VStack(spacing: 12) {
                Button(action: {
                    if activityManager.isRecording {
                        activityManager.stopActivity()
                    } else {
                        activityManager.setModelContext(modelContext)
                        activityManager.startActivity()
                    }
                }) {
                    Text(activityManager.isRecording ? "Stop Ride" : "Start Ride")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(activityManager.isRecording ? Color.red : Color.green)
                        .cornerRadius(15)
                }

                if activityManager.isRecording {
                    Button(action: {
                        if activityManager.isPaused {
                            activityManager.resumeActivity()
                        } else {
                            activityManager.pauseActivity()
                        }
                    }) {
                        Text(activityManager.isPaused ? "Resume" : "Pause")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.orange)
                            .cornerRadius(12)
                    }
                }
            }
            .padding()
        }
        .onAppear {
            locationManager.requestPermission()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
                .accessibilityLabel("Settings")
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }
    
    private func formatElevation(_ meters: Double) -> String {
        if useMetricUnits {
            return "\(Int(meters.rounded())) m"
        } else {
            let feet = meters * 3.28084
            return "\(Int(feet.rounded())) ft"
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: duration) ?? "00:00"
    }
}

struct StatBox: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title2)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

