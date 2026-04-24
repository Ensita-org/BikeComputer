import SwiftUI
import SwiftData
import UIKit

struct HistoryView: View {
    @Query(sort: \Activity.timestamp, order: .reverse) private var activities: [Activity]
    @Environment(\.modelContext) private var modelContext
    @AppStorage("useMetricUnits") private var useMetricUnits: Bool = true
    @State private var showingSettings = false
    @State private var exportedArchive: ExportedArchive?
    @State private var isExporting = false

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
            if !activities.isEmpty {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        exportAll()
                    } label: {
                        if isExporting {
                            ProgressView()
                        } else {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                    .disabled(isExporting)
                    .accessibilityLabel("Export all activities")
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(item: $exportedArchive) { archive in
            ShareSheet(items: [archive.url])
        }
        .overlay {
            if activities.isEmpty {
                ContentUnavailableView("No Rides Yet", systemImage: "bicycle", description: Text("Go for a ride to see it here."))
            }
        }
    }

    private func exportAll() {
        guard !isExporting else { return }
        isExporting = true
        // Snapshot on the main actor — Activity is a SwiftData model and
        // can't cross actor boundaries.
        let snapshots = activities.map { GPXSnapshot(filename: $0.gpxFilename, content: $0.gpxString) }
        Task.detached {
            let url = Self.createArchive(from: snapshots)
            await MainActor.run {
                isExporting = false
                if let url = url {
                    exportedArchive = ExportedArchive(url: url)
                }
            }
        }
    }

    /// Writes every activity's GPX into a temp folder, then asks
    /// NSFileCoordinator to produce a zip with `.forUploading` — a built-in
    /// iOS facility that avoids a third-party archive dependency.
    nonisolated private static func createArchive(from snapshots: [GPXSnapshot]) -> URL? {
        let fm = FileManager.default
        let workDir = fm.temporaryDirectory.appendingPathComponent("BikeComputerRides-\(UUID().uuidString)", isDirectory: true)
        do {
            try fm.createDirectory(at: workDir, withIntermediateDirectories: true)
        } catch {
            return nil
        }
        for snapshot in snapshots {
            let fileURL = workDir.appendingPathComponent(snapshot.filename)
            try? snapshot.content.write(to: fileURL, atomically: true, encoding: .utf8)
        }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withYear, .withMonth, .withDay, .withDashSeparatorInDate]
        let dateStamp = formatter.string(from: Date())
        let destination = fm.temporaryDirectory.appendingPathComponent("BikeComputer_Rides_\(dateStamp).zip")
        try? fm.removeItem(at: destination)

        var coordError: NSError?
        var finalURL: URL?
        NSFileCoordinator().coordinate(readingItemAt: workDir, options: [.forUploading], error: &coordError) { zipURL in
            do {
                try fm.copyItem(at: zipURL, to: destination)
                finalURL = destination
            } catch {
                finalURL = nil
            }
        }

        try? fm.removeItem(at: workDir)
        return finalURL
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

private struct GPXSnapshot: Sendable {
    let filename: String
    let content: String
}

private struct ExportedArchive: Identifiable {
    let id = UUID()
    let url: URL
}

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
