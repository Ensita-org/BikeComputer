import Foundation
import SwiftData

@Model
final class Activity {
    var timestamp: Date
    var distance: Double // meters
    var duration: TimeInterval // seconds
    var averageSpeed: Double // m/s
    var maxSpeed: Double // m/s
    
    @Attribute(.externalStorage) var routeData: Data? 
    
    init(timestamp: Date = Date(), distance: Double = 0, duration: TimeInterval = 0) {
        self.timestamp = timestamp
        self.distance = distance
        self.duration = duration
        self.averageSpeed = 0
        self.maxSpeed = 0
    }
}

struct RoutePoint: Codable {
    let latitude: Double
    let longitude: Double
    let altitude: Double
    let timestamp: Date
}
