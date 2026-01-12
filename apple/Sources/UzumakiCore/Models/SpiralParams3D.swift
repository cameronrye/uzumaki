import Foundation

/// Extended spiral parameters for 3D generation
/// Includes all 2D parameters plus depth-specific options
public struct SpiralParams3D: Equatable, Sendable, Codable {
    
    // MARK: - Base 2D Parameters
    
    /// The underlying 2D spiral parameters
    public var base: SpiralParams
    
    // MARK: - 3D Extension Parameters
    
    /// How the 2D spiral is extended into 3D space
    public var depthMode: SpiralDepthMode
    
    /// Overall scale factor for the 3D model (in scene units, e.g., meters)
    public var scale3D: Float
    
    /// Rotation around the X axis (radians)
    public var rotationX: Float
    
    /// Rotation around the Y axis (radians)
    public var rotationY: Float
    
    /// Rotation around the Z axis (radians)
    public var rotationZ: Float
    
    // MARK: - Mesh Generation Options
    
    /// Radius of the tube when rendering as 3D geometry
    public var tubeRadius: Float
    
    /// Number of segments around the tube circumference
    public var tubeSegments: Int
    
    // MARK: - Initialization
    
    public init(
        base: SpiralParams = .default,
        depthMode: SpiralDepthMode = .flat,
        scale3D: Float = 0.001, // Convert from screen units to meters
        rotationX: Float = 0,
        rotationY: Float = 0,
        rotationZ: Float = 0,
        tubeRadius: Float = 0.002, // 2mm default tube radius
        tubeSegments: Int = 8
    ) {
        self.base = base
        self.depthMode = depthMode
        self.scale3D = scale3D
        self.rotationX = rotationX
        self.rotationY = rotationY
        self.rotationZ = rotationZ
        self.tubeRadius = tubeRadius
        self.tubeSegments = tubeSegments
    }
    
    /// Default 3D parameters
    public static let `default` = SpiralParams3D()
    
    // MARK: - Convenience Accessors
    
    /// Spiral type from base parameters
    public var type: SpiralType {
        get { base.type }
        set { base.type = newValue }
    }
    
    /// Tightness from base parameters
    public var tightness: Double {
        get { base.tightness }
        set { base.tightness = newValue }
    }
    
    /// Spin rate from base parameters
    public var spinRate: Double {
        get { base.spinRate }
        set { base.spinRate = newValue }
    }
    
    /// Number of steps from base parameters
    public var numSteps: Int {
        get { base.numSteps }
        set { base.numSteps = newValue }
    }
    
    /// Animation time from base parameters
    public var time: Double {
        get { base.time }
        set { base.time = newValue }
    }
    
    /// Color preset from base parameters
    public var colorPreset: ColorPreset {
        get { base.colorPreset }
        set { base.colorPreset = newValue }
    }
    
    /// Effective number of steps (considering performance mode)
    public var effectiveNumSteps: Int {
        base.effectiveNumSteps
    }
}

// MARK: - Preset Configurations

extension SpiralParams3D {
    /// Flat spiral suitable for table-top AR placement
    public static var tableTop: SpiralParams3D {
        SpiralParams3D(
            base: .default,
            depthMode: .flat,
            scale3D: 0.001,
            rotationX: -.pi / 2 // Lay flat on horizontal surface
        )
    }
    
    /// Helix spiral standing upright
    public static var standingHelix: SpiralParams3D {
        SpiralParams3D(
            base: .default,
            depthMode: .helix(pitch: 30),
            scale3D: 0.001
        )
    }
    
    /// Multi-layered spiral for volumetric display
    public static var volumetric: SpiralParams3D {
        SpiralParams3D(
            base: .default,
            depthMode: .layered(count: 5, spacing: 15),
            scale3D: 0.001
        )
    }
    
    /// Bowl-shaped spiral
    public static var bowlShape: SpiralParams3D {
        SpiralParams3D(
            base: .default,
            depthMode: .bowl(depth: 40),
            scale3D: 0.001
        )
    }
}

