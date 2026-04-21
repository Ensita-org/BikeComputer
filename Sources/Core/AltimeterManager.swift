import Foundation
import CoreMotion
import Combine

class AltimeterManager: ObservableObject {
    @Published var ascent: Double = 0  // meters climbed since start
    @Published var descent: Double = 0 // meters descended since start
    @Published var currentPressure: Double = 0 // kPa, latest reading
    @Published var minPressure: Double = 0     // kPa
    @Published var maxPressure: Double = 0     // kPa
    @Published var averagePressure: Double = 0 // kPa

    private let altimeter = CMAltimeter()
    private var isRunning = false
    private var lastRelativeAltitude: Double?
    private var pressureSum: Double = 0
    private var pressureSampleCount: Int = 0

    static var isAvailable: Bool { CMAltimeter.isRelativeAltitudeAvailable() }

    func start() {
        guard !isRunning, CMAltimeter.isRelativeAltitudeAvailable() else { return }
        isRunning = true
        ascent = 0
        descent = 0
        currentPressure = 0
        minPressure = 0
        maxPressure = 0
        averagePressure = 0
        lastRelativeAltitude = nil
        pressureSum = 0
        pressureSampleCount = 0

        altimeter.startRelativeAltitudeUpdates(to: .main) { [weak self] data, _ in
            guard let self = self, let data = data else { return }
            let current = data.relativeAltitude.doubleValue
            if let last = self.lastRelativeAltitude {
                let delta = current - last
                if delta > 0 {
                    self.ascent += delta
                } else if delta < 0 {
                    self.descent += -delta
                }
            }
            self.lastRelativeAltitude = current

            let pressure = data.pressure.doubleValue
            self.currentPressure = pressure
            if self.pressureSampleCount == 0 {
                self.minPressure = pressure
                self.maxPressure = pressure
            } else {
                self.minPressure = min(self.minPressure, pressure)
                self.maxPressure = max(self.maxPressure, pressure)
            }
            self.pressureSum += pressure
            self.pressureSampleCount += 1
            self.averagePressure = self.pressureSum / Double(self.pressureSampleCount)
        }
    }

    func stop() {
        guard isRunning else { return }
        isRunning = false
        altimeter.stopRelativeAltitudeUpdates()
    }
}
