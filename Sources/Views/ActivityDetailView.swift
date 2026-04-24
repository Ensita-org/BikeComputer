import SwiftUI
import MapKit

struct ActivityDetailView: View {
    let activity: Activity
    @AppStorage("useMetricUnits") private var useMetricUnits: Bool = true
    @AppStorage("showMap") private var showMap: Bool = true

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let routeData = activity.routeData,
                   let routePoints = try? JSONDecoder().decode([RoutePoint].self, from: routeData),
                   !routePoints.isEmpty {

                    if showMap {
                        let coordinates = routePoints.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
                        Map {
                            MapPolyline(coordinates: coordinates)
                                .stroke(.blue, lineWidth: 5)
                        }
                        .environment(\.locale, mapLocale)
                        .frame(height: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                        .padding(.horizontal)
                    } else {
                        RoutePolylineView(points: routePoints)
                            .frame(height: 300)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                            .padding(.horizontal)
                    }
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
                    DetailRow(title: "Total Ascent", value: formatElevation(activity.totalAscent))
                    DetailRow(title: "Total Descent", value: formatElevation(activity.totalDescent))
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(15)
                .padding(.horizontal)

                VStack(spacing: 15) {
                    DetailRow(title: "Lowest Pressure", value: formatPressure(activity.minPressure))
                    DetailRow(title: "Highest Pressure", value: formatPressure(activity.maxPressure))
                    DetailRow(title: "Average Pressure", value: formatPressure(activity.averagePressure))
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

    private var mapLocale: Locale {
        var components = Locale.Components(locale: .current)
        components.measurementSystem = useMetricUnits ? .metric : .us
        return Locale(components: components)
    }

    private func formatElevation(_ meters: Double) -> String {
        if useMetricUnits {
            return "\(Int(meters.rounded())) m"
        } else {
            return "\(Int((meters * 3.28084).rounded())) ft"
        }
    }

    private func formatPressure(_ kilopascals: Double) -> String {
        // Store is kPa, display in hPa (millibars) — the unit weather reports use.
        let hPa = kilopascals * 10
        return String(format: "%.0f hPa", hPa)
    }
    
    private func generateGPX() -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let tempUrl = tempDir.appendingPathComponent(activity.gpxFilename)
        let gpxString = activity.gpxString
        
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

private struct RoutePolylineView: View {
    let points: [RoutePoint]

    var body: some View {
        GeometryReader { geo in
            Path { path in
                guard points.count > 1,
                      let minLat = points.map(\.latitude).min(),
                      let maxLat = points.map(\.latitude).max(),
                      let minLon = points.map(\.longitude).min(),
                      let maxLon = points.map(\.longitude).max()
                else { return }

                let latRange = max(maxLat - minLat, 0.0001)
                let lonRange = max(maxLon - minLon, 0.0001)
                // Correct longitude for the mid-latitude so the route isn't horizontally squashed.
                let lonAspect = cos((minLat + maxLat) / 2 * .pi / 180)
                let inset: CGFloat = 20
                let usableW = geo.size.width - 2 * inset
                let usableH = geo.size.height - 2 * inset
                let scale = min(usableW / (lonRange * lonAspect), usableH / latRange)
                let routeW = lonRange * lonAspect * scale
                let routeH = latRange * scale
                let xOffset = (geo.size.width - routeW) / 2
                let yOffset = (geo.size.height - routeH) / 2

                for (index, point) in points.enumerated() {
                    let x = xOffset + (point.longitude - minLon) * lonAspect * scale
                    let y = yOffset + (maxLat - point.latitude) * scale
                    let target = CGPoint(x: x, y: y)
                    if index == 0 {
                        path.move(to: target)
                    } else {
                        path.addLine(to: target)
                    }
                }
            }
            .stroke(Color.blue, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
        }
    }
}
