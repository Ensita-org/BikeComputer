import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let clLocationManager = CLLocationManager()
    
    @Published var location: CLLocation?
    @Published var speed: Double = 0.0 // m/s
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    override init() {
        super.init()
        clLocationManager.delegate = self
        clLocationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        clLocationManager.distanceFilter = 5 // Update every 5 meters
        clLocationManager.activityType = .fitness
        clLocationManager.allowsBackgroundLocationUpdates = true
        clLocationManager.pausesLocationUpdatesAutomatically = false
    }
    
    func requestPermission() {
        clLocationManager.requestWhenInUseAuthorization()
    }
    
    func startUpdates() {
        clLocationManager.startUpdatingLocation()
    }
    
    func stopUpdates() {
        clLocationManager.stopUpdatingLocation()
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }
    
    func locationManager(_ _: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latestLocation = locations.last else { return }
        
        // Filter out old or invalid cached locations
        if latestLocation.horizontalAccuracy < 0 { return }
        
        self.location = latestLocation
        
        // CoreLocation reports speed in m/s. Negative speed means invalid.
        if latestLocation.speed >= 0 {
            self.speed = latestLocation.speed
        } else {
            self.speed = 0
        }
    }
    
    func locationManager(_ _: CLLocationManager, didFailWithError error: Error) {
        print("Location Manager Error: \(error.localizedDescription)")
    }
}
