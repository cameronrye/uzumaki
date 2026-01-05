import SwiftUI

/// Color theme presets matching the web implementation
public enum ColorPreset: String, CaseIterable, Identifiable, Codable, Sendable {
    case rainbow
    case fire
    case ocean
    case neon
    case monochrome
    case sunset
    case aurora
    case candy
    case matrix
    case retro
    
    public var id: String { rawValue }
    
    /// Human-readable display name
    public var displayName: String {
        switch self {
        case .rainbow: "Rainbow"
        case .fire: "Fire"
        case .ocean: "Ocean"
        case .neon: "Neon"
        case .monochrome: "Mono"
        case .sunset: "Sunset"
        case .aurora: "Aurora"
        case .candy: "Candy"
        case .matrix: "Matrix"
        case .retro: "Retro"
        }
    }
    
    /// Color palette as SwiftUI Colors
    public var colors: [Color] {
        switch self {
        case .rainbow:
            [Color(hex: 0xFF6B6B), Color(hex: 0xFECA57), Color(hex: 0x48DBFB), 
             Color(hex: 0xFF9FF3), Color(hex: 0x54A0FF)]
        case .fire:
            [Color(hex: 0xFF0000), Color(hex: 0xFF4500), Color(hex: 0xFF8C00), 
             Color(hex: 0xFFD700), Color(hex: 0xFFFF00)]
        case .ocean:
            [Color(hex: 0x001F3F), Color(hex: 0x0074D9), Color(hex: 0x7FDBFF), 
             Color(hex: 0x39CCCC), Color(hex: 0x3D9970)]
        case .neon:
            [Color(hex: 0xFF00FF), Color(hex: 0x00FFFF), Color(hex: 0xFF00AA), 
             Color(hex: 0x00FF00), Color(hex: 0xFFFF00)]
        case .monochrome:
            [Color(hex: 0xFFFFFF), Color(hex: 0xCCCCCC), Color(hex: 0x999999), 
             Color(hex: 0x666666), Color(hex: 0xFFFFFF)]
        case .sunset:
            [Color(hex: 0xFF6B35), Color(hex: 0xF7C59F), Color(hex: 0xEFA00B), 
             Color(hex: 0xD65108), Color(hex: 0x591F0A)]
        case .aurora:
            [Color(hex: 0x00D9FF), Color(hex: 0x00FF87), Color(hex: 0xB8FF00), 
             Color(hex: 0x7B68EE), Color(hex: 0x4169E1)]
        case .candy:
            [Color(hex: 0xFF6FD8), Color(hex: 0xFF9A9E), Color(hex: 0xFECFEF), 
             Color(hex: 0xA18CD1), Color(hex: 0xFBC2EB)]
        case .matrix:
            [Color(hex: 0x00FF00), Color(hex: 0x00CC00), Color(hex: 0x009900), 
             Color(hex: 0x00FF00), Color(hex: 0x33FF33)]
        case .retro:
            [Color(hex: 0xFF00FF), Color(hex: 0x00FFFF), Color(hex: 0xFF1493), 
             Color(hex: 0xFF6EC7), Color(hex: 0x7DF9FF)]
        }
    }
}

// MARK: - Brand Colors

/// Brand colors matching the web app design system
public enum BrandColors {
    /// Primary brand color - cyan (#48dbfb)
    public static let primary = Color(hex: 0x48DBFB)

    /// Secondary brand color - coral (#ff6b6b)
    public static let secondary = Color(hex: 0xFF6B6B)

    /// Accent color - pink (#ff9ff3)
    public static let accent = Color(hex: 0xFF9FF3)

    /// Background primary - near black (#0a0a0f)
    public static let backgroundPrimary = Color(hex: 0x0A0A0F)

    /// Background gradient end - dark blue (#1a1a2e)
    public static let backgroundGradientEnd = Color(hex: 0x1A1A2E)

    /// Brand gradient (primary to secondary)
    public static var gradient: LinearGradient {
        LinearGradient(
            colors: [primary, secondary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Color Extension for Hex Support

public extension Color {
    /// Initialize a Color from a hex value (e.g., 0xFF6B6B)
    init(hex: UInt32, opacity: Double = 1.0) {
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue, opacity: opacity)
    }
}

