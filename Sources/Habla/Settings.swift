import Foundation

/// Saved settings. Stored in UserDefaults, so they survive a restart.
enum Settings {
    private nonisolated(unsafe) static let d = UserDefaults.standard

    static var holdThresholdMs: Double {
        get { d.object(forKey: "holdMs") as? Double ?? 150 }
        set { d.set(newValue, forKey: "holdMs") }
    }
    static var pasteDelayBeforeMs: Double {
        get { d.object(forKey: "pasteBeforeMs") as? Double ?? 50 }
        set { d.set(newValue, forKey: "pasteBeforeMs") }
    }
    static var pasteDelayAfterMs: Double {
        get { d.object(forKey: "pasteAfterMs") as? Double ?? 150 }
        set { d.set(newValue, forKey: "pasteAfterMs") }
    }
    static var soundsOn: Bool {
        get { d.object(forKey: "sounds") as? Bool ?? true }
        set { d.set(newValue, forKey: "sounds") }
    }
    static var model: ModelChoice {
        get { ModelChoice(rawValue: d.string(forKey: "model") ?? "") ?? .ultra }
        set { d.set(newValue.rawValue, forKey: "model") }
    }
}
