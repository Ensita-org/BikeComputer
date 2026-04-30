import SwiftUI
import SwiftData

struct ContentView: View {
    @Query private var activities: [Activity]
    @AppStorage("useMetricUnits") private var useMetricUnits: Bool = true
    @State private var showingSettings = false
    @State private var selectedPeriod: Period = .total
    @Environment(\.appBundle) private var bundle

    enum Period: String, CaseIterable, Identifiable {
        case today = "Today"
        case week = "Week"
        case month = "Month"
        case total = "All Time"
        var id: Self { self }
    }

    private var filteredActivities: [Activity] {
        let now = Date()
        let calendar = Calendar.current
        switch selectedPeriod {
        case .total:
            return activities
        case .today:
            let start = calendar.startOfDay(for: now)
            return activities.filter { $0.timestamp >= start }
        case .week:
            guard let interval = calendar.dateInterval(of: .weekOfYear, for: now) else { return [] }
            return activities.filter { $0.timestamp >= interval.start && $0.timestamp < interval.end }
        case .month:
            guard let interval = calendar.dateInterval(of: .month, for: now) else { return [] }
            return activities.filter { $0.timestamp >= interval.start && $0.timestamp < interval.end }
        }
    }

    private func periodOdometerLabel(bundle: Bundle) -> String {
        switch selectedPeriod {
        case .total: return bundle.localizedString(forKey: "All Time Odometer", value: nil, table: nil)
        case .today: return bundle.localizedString(forKey: "Today's Odometer", value: nil, table: nil)
        case .week:  return bundle.localizedString(forKey: "This Week's Odometer", value: nil, table: nil)
        case .month: return bundle.localizedString(forKey: "This Month's Odometer", value: nil, table: nil)
        }
    }

    var totalOdometer: Double {
        filteredActivities.reduce(0) { $0 + $1.distance }
    }

    var totalAscent: Double {
        filteredActivities.reduce(0) { $0 + $1.totalAscent }
    }

    var totalDescent: Double {
        filteredActivities.reduce(0) { $0 + $1.totalDescent }
    }

    var totalDuration: TimeInterval {
        filteredActivities.reduce(0) { $0 + $1.duration }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Text("Bike Computer", bundle: bundle)
                    .font(.largeTitle)
                    .fontWeight(.bold)

                // Odometer
                VStack {
                    Text(periodOdometerLabel(bundle: bundle))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(String(format: useMetricUnits ? "%.1f km" : "%.1f mi", useMetricUnits ? totalOdometer / 1000 : (totalOdometer / 1000) * 0.621371))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                }
                .padding()

                // Career totals
                HStack {
                    TotalBox(title: "Ascent", value: formatElevation(totalAscent))
                    TotalBox(title: "Descent", value: formatElevation(totalDescent))
                    TotalBox(title: "Time", value: formatTotalDuration(totalDuration))
                }
                .padding(.horizontal)

                NavigationLink(destination: DashboardView()) {
                    Label(bundle.localizedString(forKey: "Start Ride / Computer", value: nil, table: nil), systemImage: "bicycle")
                        .font(.title2)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(15)
                }

                NavigationLink(destination: HistoryView()) {
                    Label(bundle.localizedString(forKey: "History", value: nil, table: nil), systemImage: "clock")
                        .font(.title2)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.15))
                        .foregroundColor(.primary)
                        .cornerRadius(15)
                }

                Picker(selection: $selectedPeriod) {
                    ForEach(Period.allCases) { period in
                        Text(bundle.localizedString(forKey: period.rawValue, value: nil, table: nil)).tag(period)
                    }
                } label: {
                    Text("Period", bundle: bundle)
                }
                .pickerStyle(.segmented)
            }
            .padding()
            .navigationTitle(bundle.localizedString(forKey: "Menu", value: nil, table: nil))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel(bundle.localizedString(forKey: "Settings", value: nil, table: nil))
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }

    private func formatElevation(_ meters: Double) -> String {
        if useMetricUnits {
            return "\(Int(meters.rounded())) m"
        } else {
            return "\(Int((meters * 3.28084).rounded())) ft"
        }
    }

    private func formatTotalDuration(_ duration: TimeInterval) -> String {
        let totalMinutes = Int(duration / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

private struct TotalBox: View {
    let title: LocalizedStringKey
    let value: String
    @Environment(\.appBundle) private var bundle

    var body: some View {
        VStack(spacing: 4) {
            Text(title, bundle: bundle)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}
