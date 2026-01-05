import Foundation

/// Preset configurations for interesting spiral patterns
public struct SpiralPreset: Identifiable, Sendable {
    public let id: String
    public let name: String
    public let type: SpiralType
    public let tightness: Double
    public let spinRate: Double
    public let stepSize: Double
    public let numSteps: Int
    public let colorPreset: ColorPreset
    public let lineStyle: LineStyle
    public let zoom: Double
    
    public init(
        name: String,
        type: SpiralType,
        tightness: Double,
        spinRate: Double,
        stepSize: Double,
        numSteps: Int,
        colorPreset: ColorPreset,
        lineStyle: LineStyle,
        zoom: Double
    ) {
        self.id = name.lowercased().replacingOccurrences(of: " ", with: "-")
        self.name = name
        self.type = type
        self.tightness = tightness
        self.spinRate = spinRate
        self.stepSize = stepSize
        self.numSteps = numSteps
        self.colorPreset = colorPreset
        self.lineStyle = lineStyle
        self.zoom = zoom
    }
    
    /// Apply this preset to parameters, preserving unset values
    public func apply(to params: SpiralParams) -> SpiralParams {
        var result = params
        result.type = type
        result.tightness = tightness
        result.spinRate = spinRate
        result.stepSize = stepSize
        result.numSteps = numSteps
        result.colorPreset = colorPreset
        result.lineStyle = lineStyle
        result.zoom = zoom
        result.panX = 0
        result.panY = 0
        return result
    }
}

// MARK: - Built-in Presets

public extension SpiralPreset {
    static let allPresets: [SpiralPreset] = [
        classicGolden, sunflower, fractalDance, chaos, tightArchimedean,
        hypnotic, wheelOfTheodorus, trumpet, matrixRain, deepSpace
    ]
    
    static let classicGolden = SpiralPreset(
        name: "Classic Golden", type: .fibonacci, tightness: 3, spinRate: 0.3,
        stepSize: 0.1, numSteps: 500, colorPreset: .aurora, lineStyle: .glow, zoom: 1
    )
    
    static let sunflower = SpiralPreset(
        name: "Sunflower", type: .vogel, tightness: 2, spinRate: 0.1,
        stepSize: 0.1, numSteps: 1000, colorPreset: .sunset, lineStyle: .points, zoom: 2
    )
    
    static let fractalDance = SpiralPreset(
        name: "Fractal Dance", type: .curlicue, tightness: 1, spinRate: 0.2,
        stepSize: 0.1, numSteps: 800, colorPreset: .neon, lineStyle: .solid, zoom: 10
    )
    
    static let chaos = SpiralPreset(
        name: "Chaos", type: .uzumaki, tightness: 5, spinRate: 0.5,
        stepSize: 0.1, numSteps: 600, colorPreset: .rainbow, lineStyle: .dashed, zoom: 1
    )
    
    static let tightArchimedean = SpiralPreset(
        name: "Tight Archimedean", type: .archimedean, tightness: 1, spinRate: 0.5,
        stepSize: 0.05, numSteps: 1000, colorPreset: .rainbow, lineStyle: .solid, zoom: 1
    )
    
    static let hypnotic = SpiralPreset(
        name: "Hypnotic", type: .logarithmic, tightness: 2, spinRate: 1,
        stepSize: 0.15, numSteps: 300, colorPreset: .candy, lineStyle: .glow, zoom: 1.5
    )
    
    static let wheelOfTheodorus = SpiralPreset(
        name: "Wheel of Theodorus", type: .theodorus, tightness: 5, spinRate: 0.2,
        stepSize: 0.1, numSteps: 50, colorPreset: .ocean, lineStyle: .triangles, zoom: 1
    )
    
    static let trumpet = SpiralPreset(
        name: "Trumpet", type: .lituus, tightness: 4, spinRate: 0.4,
        stepSize: 0.2, numSteps: 400, colorPreset: .retro, lineStyle: .dashed, zoom: 1
    )
    
    static let matrixRain = SpiralPreset(
        name: "Matrix Rain", type: .fermat, tightness: 3, spinRate: 0.3,
        stepSize: 0.1, numSteps: 500, colorPreset: .matrix, lineStyle: .dotted, zoom: 5
    )
    
    static let deepSpace = SpiralPreset(
        name: "Deep Space", type: .hyperbolic, tightness: 5, spinRate: 0.2,
        stepSize: 0.15, numSteps: 400, colorPreset: .monochrome, lineStyle: .glow, zoom: 1
    )
}

