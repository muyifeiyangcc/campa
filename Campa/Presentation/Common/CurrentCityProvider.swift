import CoreLocation
import Foundation

final class CurrentCityProvider: NSObject {
    static let shared = CurrentCityProvider()

    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var completions: [(String?) -> Void] = []

    private override init() {
        super.init()

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func requestCurrentCity(completion: @escaping (String?) -> Void) {
        completions.append(completion)

        handleAuthorizationStatus(locationManager.authorizationStatus)
    }

    private func handleAuthorizationStatus(_ status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.requestLocation()
        case .denied, .restricted:
            finish(with: nil)
        @unknown default:
            finish(with: nil)
        }
    }

    private func reverseGeocode(_ location: CLLocation) {
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            guard let self else { return }

            let placemark = placemarks?.first
            let city = placemark?.locality ?? placemark?.subAdministrativeArea ?? placemark?.administrativeArea
            let country = placemark?.country
            let displayText = [city, country]
                .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .joined(separator: ", ")

            self.finish(with: displayText.isEmpty ? nil : displayText)
        }
    }

    private func finish(with city: String?) {
        let callbacks = completions
        completions.removeAll()
        callbacks.forEach { $0(city) }
    }
}

extension CurrentCityProvider: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        handleAuthorizationStatus(manager.authorizationStatus)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            finish(with: nil)
            return
        }

        reverseGeocode(location)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        finish(with: nil)
    }
}
