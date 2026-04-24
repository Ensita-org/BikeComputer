import Foundation
import SwiftData

@Model
final class Activity {
    var timestamp: Date
    var distance: Double // meters
    var duration: TimeInterval // seconds
    var averageSpeed: Double // m/s
    var maxSpeed: Double // m/s
    var totalAscent: Double = 0 // meters
    var totalDescent: Double = 0 // meters
    var minPressure: Double = 0 // kPa
    var maxPressure: Double = 0 // kPa
    var averagePressure: Double = 0 // kPa

    @Attribute(.externalStorage) var routeData: Data?

    init(timestamp: Date = Date(), distance: Double = 0, duration: TimeInterval = 0) {
        self.timestamp = timestamp
        self.distance = distance
        self.duration = duration
        self.averageSpeed = 0
        self.maxSpeed = 0
        self.totalAscent = 0
        self.totalDescent = 0
    }
}

struct RoutePoint: Codable {
    let latitude: Double
    let longitude: Double
    let altitude: Double
    let timestamp: Date
}

extension Activity {
    var gpxFilename: String {
        "activity_\(Int(timestamp.timeIntervalSince1970)).gpx"
    }

    var gpxString: String {
        var trackPointsXml = ""
        if let routeData = self.routeData,
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
        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1" creator="BikeComputer">
          <trk>
            <name>Ride on \(timestamp.formatted())</name>
            <trkseg>\(trackPointsXml)
            </trkseg>
          </trk>
        </gpx>
        """
    }

    @discardableResult
    func writeGPX(to directory: URL) throws -> URL {
        let url = directory.appendingPathComponent(gpxFilename)
        try gpxString.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}
