import Foundation
import CoreMotion
import Combine

class AltimeterManager: ObservableObject {
    @Published var ascent: Double = 0  // meters climbed since start
    @Published var descent: Double = 0 // meters descended since start

    private let altimeter = CMAltimeter()
    private var isRunning = false
    private var lastRelativeAltitude: Double?

    static var isAvailable: Bool { CMAltimeter.isRelativeAltitudeAvailable() }

    func start() {
        guard !isRunning, CMAltimeter.isRelativeAltitudeAvailable() else { return }
        isRunning = true
        ascent = 0
        descent = 0
        lastRelativeAltitude = nil

        altimeter.startRelativeAltitudeUpdates(to: .main) { [weak self] data, _ in
            guard let self = self, let data = data else { return }
            let current = data.relativeAltitude.doubleValue
            defer { self.lastRelativeAltitude = current }
            guard let last = self.lastRelativeAltitude else { return }
            let delta = current - last
            if delta > 0 {
                self.ascent += delta
            } else if delta < 0 {
                self.descent += -delta
            }
        }
    }

    func stop() {
        guard isRunning else { return }
        isRunning = false
        altimeter.stopRelativeAltitudeUpdates()
    }
}
