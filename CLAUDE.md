# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Role

You are an expert Swift/iOS developer. Apply idiomatic Swift patterns, leverage modern Apple frameworks (SwiftUI, SwiftData, Combine, ActivityKit), and follow Apple's Human Interface Guidelines. Prefer value types, protocol-oriented design, and Swift concurrency (`async/await`, `@MainActor`) over legacy Objective-C patterns.

## Git Workflow

All development happens on the `dev` branch. Every change must be pushed to `dev`.

```bash
git checkout dev
git push origin dev
```

Never commit directly to `main`.

## Build & Run

This is a pure Xcode project (no Swift Package Manager). Open `BikeComputer.xcodeproj`.

```bash
# Build from CLI (simulator)
xcodebuild build \
  -project BikeComputer.xcodeproj \
  -scheme BikeComputer \
  -destination 'platform=iOS Simulator,name=iPhone 16'

# Run tests (no test target currently configured)
xcodebuild test \
  -project BikeComputer.xcodeproj \
  -scheme BikeComputer \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

**Targets:**
- `BikeComputer` — main app (iOS 16.1+)
- `BikeComputerWidget` — lock screen / Live Activity widget

## Architecture

The app follows **MVVM with Manager-based services**. SwiftUI views observe `@ObservableObject` managers that encapsulate sensor and data logic.

```
Views (SwiftUI)
  └── observe via @StateObject / @EnvironmentObject
       ↓
Managers (@ObservableObject, live in Sources/Core/)
  ├── ActivityManager    ← orchestrates a recording session end-to-end
  ├── LocationManager    ← CoreLocation wrapper, publishes speed & coordinates
  ├── AltimeterManager   ← CoreMotion barometer, publishes elevation & pressure
  └── WeatherManager     ← Open-Meteo REST API
       ↓
Persistence (SwiftData)
  └── Activity           ← single @Model entity; route stored as external JSON blob
```

### Recording data flow

1. `DashboardView` calls `ActivityManager.startActivity()`.
2. `ActivityManager` starts a timer, activates `LocationManager` and `AltimeterManager`, and launches a Live Activity via ActivityKit.
3. CoreLocation updates flow into `LocationManager.$location` (Combine). `ActivityManager` subscribes, accumulates distance, speed, and `[RoutePoint]`.
4. Barometric samples flow from `AltimeterManager` into elevation gain/loss and pressure stats.
5. On stop, `ActivityManager` creates an `Activity` SwiftData record and ends the Live Activity.

### Key files

| File | Role |
|------|------|
| `Sources/App/BikeComputerApp.swift` | App entry, SwiftData `ModelContainer` setup |
| `Sources/Core/ActivityManager.swift` | Recording lifecycle, sensor orchestration, state machine |
| `Sources/Core/LocationManager.swift` | CoreLocation wrapper; speed decay >3 s without update |
| `Sources/Core/AltimeterManager.swift` | Barometric elevation; cumulative ascent/descent |
| `Sources/Core/WeatherManager.swift` | Open-Meteo API; gated by privacy setting |
| `Sources/Models/Activity.swift` | SwiftData model; GPX export generation |
| `Sources/Models/BikeActivityAttributes.swift` | LiveActivity content state contract |
| `Sources/Views/DashboardView.swift` | Live metrics display + recording controls |
| `Sources/Views/ContentView.swift` | Home/stats aggregation, period filter |
| `Sources/Views/HistoryView.swift` | Ride list, bulk GPX zip export |
| `Sources/Views/ActivityDetailView.swift` | Per-ride map, stats, individual GPX export |
| `Sources/Views/SettingsView.swift` | User preferences (units, privacy toggles, screen lock) |
| `Sources/Intents/BikeComputerIntents.swift` | AppIntents for lock-screen widget controls |
| `BikeComputerWidget/BikeComputerWidget.swift` | Dynamic Island + lock screen Live Activity UI |

### Data model

```swift
@Model final class Activity {
    var timestamp: Date
    var distance: Double          // meters
    var duration: TimeInterval    // seconds
    var averageSpeed, maxSpeed: Double   // m/s
    var totalAscent, totalDescent: Double  // meters (barometric)
    var minPressure, maxPressure, averagePressure: Double  // kPa
    @Attribute(.externalStorage) var routeData: Data?  // JSON [RoutePoint]
}

struct RoutePoint: Codable {
    let latitude, longitude, altitude: Double
    let timestamp: Date
}
```

`routeData` uses SwiftData external storage — deserialize with `JSONDecoder` before use.

### Live Activity contract

`BikeActivityAttributes.ContentState` is the shared type between the app and widget targets. Any property added here must compile in both targets.

## Important implementation details

- **Speed decay**: `LocationManager` zeroes out speed if no CoreLocation update arrives within 3 seconds.
- **Pause accounting**: `ActivityManager` tracks cumulative pause duration; elapsed time = wall time − pause time.
- **Background GPS**: `UIBackgroundModes: location` is enabled. Location accuracy and distance filter are tuned for cycling (5 m filter).
- **Unit conversion**: UI displays values in metric or imperial based on `SettingsView` preference; internal storage is always SI (meters, m/s).
- **GPX export**: Generated in `Activity.swift` from `[RoutePoint]`; bulk export zips individual files via `NSFileCoordinator`.
- **Privacy gates**: Weather API calls and MapKit tile requests are individually opt-out in Settings.
- **iOS version guard**: Live Activities require `@available(iOS 16.1, *)` — keep this guard wherever ActivityKit APIs are used.
