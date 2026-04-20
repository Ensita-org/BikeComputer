import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \Activity.timestamp, order: .reverse) private var activities: [Activity]
    @Environment(\.modelContext) private var modelContext
    @AppStorage("useMetricUnits") private var useMetricUnits: Bool = true
    @State private var showingSettings = false

    var body: some View {
        List {
            ForEach(activities) { activity in
                NavigationLink(destination: ActivityDetailView(activity: activity)) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(activity.timestamp, style: .date)
                                .font(.headline)
                            Text(activity.timestamp, style: .time)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing) {
                            Text(formatDistance(activity.distance))
                                .fontWeight(.bold)
                            Text(formatDuration(activity.duration))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .onDelete(perform: deleteItems)
        }
        .navigationTitle("History")
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
        .overlay {
            if activities.isEmpty {
                ContentUnavailableView("No Rides Yet", systemImage: "bicycle", description: Text("Go for a ride to see it here."))
            }
        }
    }

    private func formatDistance(_ meters: Double) -> String {
        let km = meters / 1000
        if useMetricUnits {
            return String(format: "%.2f km", km)
        } else {
            return String(format: "%.2f mi", km * 0.621371)
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(activities[index])
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? "0m"
    }
}
