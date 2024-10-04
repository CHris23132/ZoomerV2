import Foundation
import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var locationPermissionGranted: Bool = false
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        requestLocationPermission()  // Request permission when the manager is initialized
    }
    
    /// Requests location permission from the user
    func requestLocationPermission() {
        let status = CLLocationManager.authorizationStatus()
        
        // Request permission if it hasn't been determined
        if status == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        } else {
            handleAuthorizationStatus(status)
        }
    }
    
    /// Starts updating the location continuously
    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }
    
    /// Stops updating the location
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    // MARK: - CLLocationManagerDelegate Methods
    
    /// Called whenever the location is updated
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            userLocation = location.coordinate
            locationPermissionGranted = true
        }
    }
    
    /// Called when the authorization status changes
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        handleAuthorizationStatus(status)
    }
    
    /// Handles different authorization statuses
    private func handleAuthorizationStatus(_ status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            locationPermissionGranted = true
            startUpdatingLocation()
        case .denied, .restricted:
            locationPermissionGranted = false
        case .notDetermined:
            // Location permissions not determined yet
            locationPermissionGranted = false
        @unknown default:
            locationPermissionGranted = false
        }
    }
}
