import SwiftUI

/// Line rendering styles matching the web implementation
public enum LineStyle: String, CaseIterable, Identifiable, Codable, Sendable {
    case solid
    case dashed
    case dotted
    case glow
    case points
    case triangles
    
    public var id: String { rawValue }
    
    /// Human-readable display name
    public var displayName: String {
        switch self {
        case .solid: "Solid"
        case .dashed: "Dashed"
        case .dotted: "Dotted"
        case .glow: "Glow Only"
        case .points: "Points"
        case .triangles: "Triangles"
        }
    }
    
    /// Dash pattern for StrokeStyle (empty for solid lines)
    public var dashPattern: [CGFloat] {
        switch self {
        case .solid, .glow, .points, .triangles: []
        case .dashed: [10, 5]
        case .dotted: [2, 4]
        }
    }
}

/// Background theme options (named to avoid SwiftUI.BackgroundStyle collision)
public enum BackgroundTheme: String, CaseIterable, Identifiable, Codable, Sendable {
    case dark
    case black
    case gradient
    case matching

    public var id: String { rawValue }

    /// Human-readable display name
    public var displayName: String {
        switch self {
        case .dark: "Dark"
        case .black: "Pure Black"
        case .gradient: "Gradient"
        case .matching: "Match Colors"
        }
    }

    /// Base color for the background
    public var baseColor: Color {
        switch self {
        case .dark: Color(hex: 0x0A0A0F)
        case .black: .black
        case .gradient: Color(hex: 0x0A0A0F)
        case .matching: Color(hex: 0x0A0A0F)
        }
    }
}

