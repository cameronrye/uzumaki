import Foundation

/// Defines how 2D spiral points are extended into 3D space
public enum SpiralDepthMode: Equatable, Sendable, Codable {
    /// All points remain on a flat plane at z = 0
    case flat
    
    /// Spiral extends upward as a helix with specified pitch (z increase per full rotation)
    case helix(pitch: Float)
    
    /// Creates multiple copies of the spiral at different z levels
    case layered(count: Int, spacing: Float)
    
    /// Spiral expands outward in a cone shape
    case cone(angle: Float)
    
    /// Points rise based on their distance from center
    case bowl(depth: Float)
}

// MARK: - Default Values

extension SpiralDepthMode {
    /// Default helix with moderate pitch
    public static let defaultHelix = SpiralDepthMode.helix(pitch: 50.0)
    
    /// Default layered with 3 levels
    public static let defaultLayered = SpiralDepthMode.layered(count: 3, spacing: 20.0)
    
    /// Default cone with 30 degree angle
    public static let defaultCone = SpiralDepthMode.cone(angle: 0.5236) // 30 degrees in radians
    
    /// Default bowl with moderate depth
    public static let defaultBowl = SpiralDepthMode.bowl(depth: 50.0)
}

// MARK: - Display Names

extension SpiralDepthMode {
    /// Human-readable name for UI display
    public var displayName: String {
        switch self {
        case .flat:
            return "Flat"
        case .helix:
            return "Helix"
        case .layered:
            return "Layered"
        case .cone:
            return "Cone"
        case .bowl:
            return "Bowl"
        }
    }
    
    /// Description of the depth mode effect
    public var description: String {
        switch self {
        case .flat:
            return "2D spiral on a flat plane"
        case .helix(let pitch):
            return "Spiral rises \(Int(pitch)) units per rotation"
        case .layered(let count, let spacing):
            return "\(count) layers, \(Int(spacing)) units apart"
        case .cone(let angle):
            let degrees = Int(angle * 180 / .pi)
            return "Expands at \(degrees) degree angle"
        case .bowl(let depth):
            return "Bowl shape, \(Int(depth)) units deep"
        }
    }
}

// MARK: - Codable Conformance

extension SpiralDepthMode {
    private enum CodingKeys: String, CodingKey {
        case type, pitch, count, spacing, angle, depth
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        
        switch type {
        case "flat":
            self = .flat
        case "helix":
            let pitch = try container.decode(Float.self, forKey: .pitch)
            self = .helix(pitch: pitch)
        case "layered":
            let count = try container.decode(Int.self, forKey: .count)
            let spacing = try container.decode(Float.self, forKey: .spacing)
            self = .layered(count: count, spacing: spacing)
        case "cone":
            let angle = try container.decode(Float.self, forKey: .angle)
            self = .cone(angle: angle)
        case "bowl":
            let depth = try container.decode(Float.self, forKey: .depth)
            self = .bowl(depth: depth)
        default:
            self = .flat
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .flat:
            try container.encode("flat", forKey: .type)
        case .helix(let pitch):
            try container.encode("helix", forKey: .type)
            try container.encode(pitch, forKey: .pitch)
        case .layered(let count, let spacing):
            try container.encode("layered", forKey: .type)
            try container.encode(count, forKey: .count)
            try container.encode(spacing, forKey: .spacing)
        case .cone(let angle):
            try container.encode("cone", forKey: .type)
            try container.encode(angle, forKey: .angle)
        case .bowl(let depth):
            try container.encode("bowl", forKey: .type)
            try container.encode(depth, forKey: .depth)
        }
    }
}

