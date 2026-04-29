import Foundation
import CoreLocation

struct ParsedRide {
    let timestamp: Date
    let points: [RoutePoint]
    let distance: Double
    let duration: TimeInterval
    let averageSpeed: Double
    let maxSpeed: Double
}

// SAX-based GPX parser. Handles standard GPX 1.1 from BikeComputer exports
// and common third-party exporters (Strava, Komoot, Garmin). Multiple <trkseg>
// blocks are flattened into a single point list.
final class GPXParser: NSObject, XMLParserDelegate {
    private var points: [RoutePoint] = []
    private var metadataTimestamp: Date?

    private var insideTrkpt = false
    private var insideMetadataTime = false
    private var currentLat: Double?
    private var currentLon: Double?
    private var currentEle: Double = 0
    private var currentTime: Date?
    private var currentText = ""

    private let isoFormatter = ISO8601DateFormatter()

    func parse(data: Data) -> ParsedRide? {
        points = []
        metadataTimestamp = nil
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
        guard points.count >= 2 else { return nil }
        return buildRide()
    }

    // MARK: - XMLParserDelegate

    func parser(_ parser: XMLParser,
                didStartElement elementName: String,
                namespaceURI: String?,
                qualifiedName: String?,
                attributes attributeDict: [String: String] = [:]) {
        currentText = ""
        switch elementName {
        case "trkpt":
            insideTrkpt = true
            currentLat = attributeDict["lat"].flatMap(Double.init)
            currentLon = attributeDict["lon"].flatMap(Double.init)
            currentEle = 0
            currentTime = nil
        case "time" where !insideTrkpt:
            insideMetadataTime = true
        default:
            break
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentText += string
    }

    func parser(_ parser: XMLParser,
                didEndElement elementName: String,
                namespaceURI: String?,
                qualifiedName: String?) {
        let text = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
        switch elementName {
        case "ele" where insideTrkpt:
            currentEle = Double(text) ?? 0
        case "time" where insideTrkpt:
            currentTime = isoFormatter.date(from: text)
        case "time" where insideMetadataTime:
            metadataTimestamp = isoFormatter.date(from: text)
            insideMetadataTime = false
        case "trkpt":
            if let lat = currentLat, let lon = currentLon, let ts = currentTime {
                points.append(RoutePoint(latitude: lat, longitude: lon, altitude: currentEle, timestamp: ts))
            }
            insideTrkpt = false
        default:
            break
        }
        currentText = ""
    }

    // MARK: - Stats

    private func buildRide() -> ParsedRide {
        var totalDistance: Double = 0
        var maxSpeed: Double = 0

        for i in 1..<points.count {
            let prev = points[i - 1]
            let curr = points[i]
            let d = CLLocation(latitude: curr.latitude, longitude: curr.longitude)
                .distance(from: CLLocation(latitude: prev.latitude, longitude: prev.longitude))
            totalDistance += d
            let dt = curr.timestamp.timeIntervalSince(prev.timestamp)
            if dt > 0 { maxSpeed = max(maxSpeed, d / dt) }
        }

        let rideStart = metadataTimestamp ?? points.first!.timestamp
        let duration = max(0, points.last!.timestamp.timeIntervalSince(points.first!.timestamp))
        let avgSpeed = duration > 0 ? totalDistance / duration : 0

        return ParsedRide(
            timestamp: rideStart,
            points: points,
            distance: totalDistance,
            duration: duration,
            averageSpeed: avgSpeed,
            maxSpeed: maxSpeed
        )
    }
}
