import SwiftUI
import MapKit

struct ActivityDetailView: View {
    let activity: Activity
    @AppStorage("useMetricUnits") private var useMetricUnits: Bool = true

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let routeData = activity.routeData,
                   let routePoints = try? JSONDecoder().decode([RoutePoint].self, from: routeData),
                   !routePoints.isEmpty {
                    
                    let coordinates = routePoints.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
                    
                    Map {
                        MapPolyline(coordinates: coordinates)
                            .stroke(.blue, lineWidth: 5)
                    }
                    .frame(height: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .padding(.horizontal)
                } else {
                    // Fallback if no route data
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 250)
                        .overlay(
                            Text("No route data available")
                                .foregroundColor(.secondary)
                        )
                        .cornerRadius(15)
                        .padding(.horizontal)
                }
                
                // Stats
                VStack(spacing: 15) {
                    DetailRow(title: "Date", value: activity.timestamp.formatted(date: .long, time: .shortened))
                    DetailRow(title: "Distance", value: formatDistance(activity.distance))
                    DetailRow(title: "Duration", value: formatDuration(activity.duration))
                    DetailRow(title: "Avg Speed", value: formatSpeed(activity.averageSpeed))
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(15)
                .padding(.horizontal)
                
                // Export Button
                ShareLink(item: generateGPX(), preview: SharePreview("Activity GPX", image: Image(systemName: "map"))) {
                    Label("Export GPX", systemImage: "square.and.arrow.up")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
            }
        }
        .navigationTitle("Ride Details")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .full
        return formatter.string(from: duration) ?? "00:00"
    }

    private func formatDistance(_ meters: Double) -> String {
        let km = meters / 1000
        return useMetricUnits
            ? String(format: "%.2f km", km)
            : String(format: "%.2f mi", km * 0.621371)
    }

    private func formatSpeed(_ metersPerSecond: Double) -> String {
        let kph = metersPerSecond * 3.6
        return useMetricUnits
            ? String(format: "%.1f km/h", kph)
            : String(format: "%.1f mph", kph * 0.621371)
    }
    
    private func generateGPX() -> URL {
        let fileName = "activity_\(Int(activity.timestamp.timeIntervalSince1970)).gpx"
        let tempUrl = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        var trackPointsXml = ""
        
        if let routeData = activity.routeData,
           let routePoints = try? JSONDecoder().decode([RoutePoint].self, from: routeData) {
            
            let dateFormatter = ISO8601DateFormatter()
            
            for point in routePoints {
                trackPointsXml += """
                
                    <trkpt lat="\(point.latitude)" lon="\(point.longitude)">
                        <ele>\(point.altitude)</ele>
                        <time>\(dateFormatter.string(from: point.timestamp))</time>
                    </trkpt>
                """
            }
        }
        
        let gpxString = """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1" creator="BikeComputer">
          <trk>
            <name>Ride on \(activity.timestamp.formatted())</name>
            <trkseg>\(trackPointsXml)
            </trkseg>
          </trk>
        </gpx>
        """
        
        try? gpxString.write(to: tempUrl, atomically: true, encoding: .utf8)
        return tempUrl
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}
