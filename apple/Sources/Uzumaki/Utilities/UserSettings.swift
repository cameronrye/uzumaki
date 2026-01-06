import Foundation
import SwiftUI
import UzumakiCore

/// Manages user preferences and spiral state persistence
@MainActor
public final class UserSettings {
    
    // MARK: - Singleton
    
    public static let shared = UserSettings()
    
    private init() {}
    
    // MARK: - Keys
    
    private enum Keys {
        static let spiralType = "spiralType"
        static let colorPreset = "colorPreset"
        static let lineStyle = "lineStyle"
        static let backgroundTheme = "backgroundTheme"
        static let performanceMode = "performanceMode"
        static let lineThicknessVariation = "lineThicknessVariation"
        static let spinRate = "spinRate"
        static let tightness = "tightness"
        static let stepSize = "stepSize"
        static let numSteps = "numSteps"
        static let hasLaunchedBefore = "hasLaunchedBefore"
    }
    
    // MARK: - User Defaults
    
    private var defaults: UserDefaults { .standard }
    
    // MARK: - Properties
    
    public var hasLaunchedBefore: Bool {
        get { defaults.bool(forKey: Keys.hasLaunchedBefore) }
        set { defaults.set(newValue, forKey: Keys.hasLaunchedBefore) }
    }
    
    public var spiralType: SpiralType {
        get {
            guard let raw = defaults.string(forKey: Keys.spiralType),
                  let type = SpiralType(rawValue: raw) else {
                return .archimedean
            }
            return type
        }
        set { defaults.set(newValue.rawValue, forKey: Keys.spiralType) }
    }
    
    public var colorPreset: ColorPreset {
        get {
            guard let raw = defaults.string(forKey: Keys.colorPreset),
                  let preset = ColorPreset(rawValue: raw) else {
                return .rainbow
            }
            return preset
        }
        set { defaults.set(newValue.rawValue, forKey: Keys.colorPreset) }
    }
    
    public var lineStyle: LineStyle {
        get {
            guard let raw = defaults.string(forKey: Keys.lineStyle),
                  let style = LineStyle(rawValue: raw) else {
                return .solid
            }
            return style
        }
        set { defaults.set(newValue.rawValue, forKey: Keys.lineStyle) }
    }
    
    public var backgroundTheme: BackgroundTheme {
        get {
            guard let raw = defaults.string(forKey: Keys.backgroundTheme),
                  let theme = BackgroundTheme(rawValue: raw) else {
                return .dark
            }
            return theme
        }
        set { defaults.set(newValue.rawValue, forKey: Keys.backgroundTheme) }
    }
    
    public var performanceMode: Bool {
        get { defaults.bool(forKey: Keys.performanceMode) }
        set { defaults.set(newValue, forKey: Keys.performanceMode) }
    }
    
    public var lineThicknessVariation: Bool {
        get { defaults.bool(forKey: Keys.lineThicknessVariation) }
        set { defaults.set(newValue, forKey: Keys.lineThicknessVariation) }
    }
    
    public var spinRate: Double {
        get {
            let value = defaults.double(forKey: Keys.spinRate)
            return value == 0 ? 0.5 : value  // Default to 0.5 if not set
        }
        set { defaults.set(newValue, forKey: Keys.spinRate) }
    }
    
    public var tightness: Double {
        get {
            let value = defaults.double(forKey: Keys.tightness)
            return value == 0 ? 3.0 : value  // Default to 3.0 if not set
        }
        set { defaults.set(newValue, forKey: Keys.tightness) }
    }
    
    public var stepSize: Double {
        get {
            let value = defaults.double(forKey: Keys.stepSize)
            return value == 0 ? 0.1 : value  // Default to 0.1 if not set
        }
        set { defaults.set(newValue, forKey: Keys.stepSize) }
    }
    
    public var numSteps: Int {
        get {
            let value = defaults.integer(forKey: Keys.numSteps)
            return value == 0 ? 500 : value  // Default to 500 if not set
        }
        set { defaults.set(newValue, forKey: Keys.numSteps) }
    }
}

