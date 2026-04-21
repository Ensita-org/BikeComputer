import Foundation
import CoreLocation
import SwiftData
import Combine
import UIKit
import ActivityKit

class ActivityManager: ObservableObject {
    @Published var isRecording = false
    @Published var isPaused: Bool = false
    @Published var elapsedTime: TimeInterval = 0
    @Published var distance: Double = 0 // meters
    @Published var currentSpeed: Double = 0 // m/s
    @Published var averageSpeed: Double = 0 // m/s
    @Published var ascent: Double = 0 // meters
    @Published var descent: Double = 0 // meters
    @Published var currentPressure: Double = 0 // kPa

    private var locationManager: LocationManager
    private let altimeterManager = AltimeterManager()
    private var modelContext: ModelContext?

    private var timer: Timer?
    private var startTime: Date?
    private var pauseStartTime: Date?
    private var totalPausedDuration: TimeInterval = 0
    private var lastLocation: CLLocation?
    private var routePoints: [RoutePoint] = []

    private var locationsCancellable: AnyCancellable?
    private var altimeterCancellables = Set<AnyCancellable>()
    private var liveActivity: ActivityKit.Activity<BikeActivityAttributes>?
    
    init(locationManager: LocationManager) {
        self.locationManager = locationManager
        
        // Subscribe to location updates
        locationsCancellable = locationManager.$location
            .sink { [weak self] location in
                self?.handleLocationUpdate(location)
            }
            
        setupIntentListeners()
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    private func setupIntentListeners() {
        NotificationCenter.default.addObserver(forName: Notification.Name("pauseActivity"), object: nil, queue: .main) { [weak self] _ in
            self?.pauseActivity()
        }
        
        NotificationCenter.default.addObserver(forName: Notification.Name("resumeActivity"), object: nil, queue: .main) { [weak self] _ in
            self?.resumeActivity()
        }
        
        NotificationCenter.default.addObserver(forName: Notification.Name("stopActivity"), object: nil, queue: .main) { [weak self] _ in
            self?.stopActivity()
        }
    }
    
    func startActivity() {
        guard !isRecording else { return }
        
        isRecording = true
        isPaused = false
        startTime = Date()
        pauseStartTime = nil
        totalPausedDuration = 0
        elapsedTime = 0
        distance = 0
        averageSpeed = 0
        ascent = 0
        descent = 0
        currentPressure = 0
        routePoints = []
        lastLocation = nil

        // Prevent screen from sleeping if setting is enabled
        let preventLock = UserDefaults.standard.object(forKey: "preventScreenLock") as? Bool ?? true
        if preventLock {
            UIApplication.shared.isIdleTimerDisabled = true
        }

        locationManager.startUpdates()
        altimeterManager.start()
        altimeterCancellables.removeAll()
        altimeterManager.$ascent
            .assign(to: \.ascent, on: self)
            .store(in: &altimeterCancellables)
        altimeterManager.$descent
            .assign(to: \.descent, on: self)
            .store(in: &altimeterCancellables)
        altimeterManager.$currentPressure
            .assign(to: \.currentPressure, on: self)
            .store(in: &altimeterCancellables)
        startLiveActivity()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateElapsedTime()
        }
    }
    
    func stopActivity() {
        guard isRecording else { return }
        
        isRecording = false
        timer?.invalidate()
        timer = nil
        
        locationManager.stopUpdates()
        altimeterManager.stop()
        altimeterCancellables.removeAll()

        // Allow screen to sleep
        UIApplication.shared.isIdleTimerDisabled = false
        
        if isPaused, let pauseStart = pauseStartTime {
             // If stopped while paused, update final duration
             totalPausedDuration += Date().timeIntervalSince(pauseStart)
         }
        
        isPaused = false
        updateElapsedTime() // Final update
        endLiveActivity()
        
        saveActivity()
    }
    
    func pauseActivity() {
        guard isRecording, !isPaused else { return }
        isPaused = true
        pauseStartTime = Date()
        updateLiveActivity()
    }

    func resumeActivity() {
        guard isRecording, isPaused else { return }
        isPaused = false
        if let pauseStart = pauseStartTime {
            totalPausedDuration += Date().timeIntervalSince(pauseStart)
        }
        pauseStartTime = nil
        updateLiveActivity()
    }
    
    private func updateElapsedTime() {
        guard let start = startTime, !isPaused else { return }
        let now = Date()
        // Current elapsed = (now - start) - totalPausedDuration
        self.elapsedTime = now.timeIntervalSince(start) - totalPausedDuration
        updateLiveActivity()
    }
    
    private func handleLocationUpdate(_ location: CLLocation?) {
        guard isRecording, !isPaused, let location = location else { return }
        
        // Add to route
        let point = RoutePoint(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            altitude: location.altitude,
            timestamp: location.timestamp
        )
        routePoints.append(point)
        
        currentSpeed = max(0, location.speed)
        
        if let last = lastLocation {
            let delta = location.distance(from: last)
            distance += delta
        }
        
        lastLocation = location
        
        // Update average speed (m/s)
        if elapsedTime > 0 {
            averageSpeed = distance / elapsedTime
        }
        
        updateLiveActivity()
    }
    
    // MARK: - Live Activity
    
    private func startLiveActivity() {
        // Only available on iOS 16.1+
        if #available(iOS 16.1, *) {
            guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
            
            let attributes = BikeActivityAttributes(startTime: startTime ?? Date())
            let contentState = BikeActivityAttributes.ContentState(
                currentSpeed: currentSpeed,
                distance: distance,
                duration: elapsedTime,
                isPaused: isPaused,
                useMetricUnits: UserDefaults.standard.bool(forKey: "useMetricUnits")
            )
            
            do {
                liveActivity = try ActivityKit.Activity.request(
                    attributes: attributes,
                    content: .init(state: contentState, staleDate: nil),
                    pushType: nil
                )
            } catch {
                print("Error starting Live Activity: \(error.localizedDescription)")
            }
        }
    }
    
    private func updateLiveActivity() {
        guard let activity = liveActivity else { return }
        
        Task {
            let contentState = BikeActivityAttributes.ContentState(
                currentSpeed: currentSpeed,
                distance: distance,
                duration: elapsedTime,
                isPaused: isPaused,
                useMetricUnits: UserDefaults.standard.bool(forKey: "useMetricUnits")
            )
            
            await activity.update(
                ActivityContent(state: contentState, staleDate: nil)
            )
        }
    }
    
    private func endLiveActivity() {
        guard let activity = liveActivity else { return }
        
        Task {
            let contentState = BikeActivityAttributes.ContentState(
                currentSpeed: currentSpeed,
                distance: distance,
                duration: elapsedTime,
                isPaused: isPaused,
                useMetricUnits: UserDefaults.standard.bool(forKey: "useMetricUnits")
            )
            
            await activity.end(
                ActivityContent(state: contentState, staleDate: nil),
                dismissalPolicy: .immediate
            )
            self.liveActivity = nil
        }
    }
    
    private func saveActivity() {
        guard let context = modelContext else { return }
        
        let activity = Activity(
            timestamp: startTime ?? Date(),
            distance: distance,
            duration: elapsedTime
        )
        activity.averageSpeed = averageSpeed
        activity.totalAscent = ascent
        activity.totalDescent = descent
        activity.minPressure = altimeterManager.minPressure
        activity.maxPressure = altimeterManager.maxPressure
        activity.averagePressure = altimeterManager.averagePressure
        
        // Save route data
        if let encodedRoute = try? JSONEncoder().encode(routePoints) {
            activity.routeData = encodedRoute
        }
        
        context.insert(activity)
        
        do {
            try context.save()
            print("Activity saved with \(routePoints.count) points!")
        } catch {
            print("Failed to save activity: \(error)")
        }
    }
}
