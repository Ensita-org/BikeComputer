import ActivityKit
import Foundation

struct BikeActivityAttributes: ActivityAttributes {
    public typealias BikeStatus = ContentState
    
    public struct ContentState: Codable, Hashable {
        // Dynamic state
        var currentSpeed: Double
        var distance: Double
        var duration: TimeInterval
        var isPaused: Bool
        var useMetricUnits: Bool
    }
    
    // Static data
    var startTime: Date
}
