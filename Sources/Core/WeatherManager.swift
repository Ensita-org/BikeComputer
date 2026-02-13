import Foundation
import CoreLocation
import Combine

struct WeatherInfo {
    let temperature: Double // Celsius
    let condition: String
    let iconName: String
}

@MainActor
class WeatherManager: ObservableObject {
    
    @Published var currentWeather: WeatherInfo?
    
    // Placeholder for API Key or use a free open API that doesn't need auth (rare)
    // For now, we simulate weather or use a public free endpoint if available.
    // open-meteo.com offers free weather API without key!
    
    func fetchWeather(for location: CLLocation) async {
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        
        // Using Open-Meteo API (Free, no key required)
        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=\(lat)&longitude=\(lon)&current_weather=true"
        
        guard let url = URL(string: urlString) else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoder = JSONDecoder()
            let response = try decoder.decode(OpenMeteoResponse.self, from: data)
            
            self.currentWeather = WeatherInfo(
                temperature: response.current_weather.temperature,
                condition: self.mapWmoCode(response.current_weather.weathercode),
                iconName: self.mapWmoIcon(response.current_weather.weathercode)
            )
        } catch {
            print("Weather fetch failed: \(error)")
        }
    }
    
    private func mapWmoCode(_ code: Int) -> String {
        switch code {
        case 0: return "Clear Sky"
        case 1, 2, 3: return "Mainly Clear"
        case 45, 48: return "Fog"
        case 51...55: return "Drizzle"
        case 61...67: return "Rain"
        case 71...77: return "Snow"
        case 80...82: return "Rain Showers"
        case 95...99: return "Thunderstorm"
        default: return "Unknown"
        }
    }
    
    private func mapWmoIcon(_ code: Int) -> String {
        switch code {
        case 0: return "sun.max.fill"
        case 1, 2, 3: return "cloud.sun.fill"
        case 45, 48: return "cloud.fog.fill"
        case 51...55: return "cloud.drizzle.fill"
        case 61...67: return "cloud.rain.fill"
        case 71...77: return "cloud.snow.fill"
        case 80...82: return "cloud.heavyrain.fill"
        case 95...99: return "cloud.bolt.fill"
        default: return "questionmark.circle"
        }
    }
}

// Decodable structs for Open-Meteo
struct OpenMeteoResponse: Decodable {
    let current_weather: CurrentWeather
}

struct CurrentWeather: Decodable {
    let temperature: Double
    let weathercode: Int
    let windspeed: Double
}
