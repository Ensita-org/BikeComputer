import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \Activity.timestamp, order: .reverse) private var activities: [Activity]
    @Environment(\.modelContext) private var modelContext
    
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
                            Text(String(format: "%.2f km", activity.distance / 1000))
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
        .overlay {
            if activities.isEmpty {
                ContentUnavailableView("No Rides Yet", systemImage: "bicycle", description: Text("Go for a ride to see it here."))
            }
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
