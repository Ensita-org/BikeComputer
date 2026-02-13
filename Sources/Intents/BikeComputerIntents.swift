import AppIntents
import Foundation

@available(iOS 16.0, *)
struct PauseActivityIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Pause Activity"
    
    public init() {}
    
    public func perform() async throws -> some IntentResult {
        // notification center or singleton to handle this?
        // In a complex app, we'd use a dependency injection system.
        // For now, let's post a notification that ActivityManager listens to.
        NotificationCenter.default.post(name: Notification.Name("pauseActivity"), object: nil)
        return .result()
    }
}

@available(iOS 16.0, *)
struct ResumeActivityIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Resume Activity"
    
    public init() {}
    
    public func perform() async throws -> some IntentResult {
        NotificationCenter.default.post(name: Notification.Name("resumeActivity"), object: nil)
        return .result()
    }
}

@available(iOS 16.0, *)
struct StopActivityIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Stop Activity"
    
    public init() {}
    
    public func perform() async throws -> some IntentResult {
        NotificationCenter.default.post(name: Notification.Name("stopActivity"), object: nil)
        return .result()
    }
}

