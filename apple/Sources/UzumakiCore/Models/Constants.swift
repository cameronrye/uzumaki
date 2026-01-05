import Foundation

/// Application constants matching the web implementation
public enum Constants {
    // MARK: - Animation
    public static let animationFPSNormal: Double = 60
    public static let animationFPSPerformance: Double = 30
    public static let toastDurationSeconds: Double = 2.0
    public static let onboardingAutoHideSeconds: Double = 4.0
    
    // MARK: - Zoom and Pan
    public static let zoomMin: Double = 0.1
    public static let zoomMax: Double = 10.0
    public static let zoomFactorIn: Double = 1.1
    public static let zoomFactorOut: Double = 0.9
    public static let panLimit: Double = 10000
    
    // MARK: - Spiral Parameters
    public static let spinRateMin: Double = 0
    public static let spinRateMax: Double = 2
    public static let spinRateStep: Double = 0.01
    public static let spinRateKeyboardStep: Double = 0.1
    
    public static let tightnessMin: Double = 0.5
    public static let tightnessMax: Double = 10
    public static let tightnessStep: Double = 0.1
    
    public static let stepSizeMin: Double = 0.01
    public static let stepSizeMax: Double = 0.5
    public static let stepSizeStep: Double = 0.01
    
    public static let numStepsMin: Int = 50
    public static let numStepsMax: Int = 2000
    public static let numStepsStep: Int = 10
    public static let numStepsPerformanceMax: Int = 500
    
    // MARK: - Viewport
    public static let viewportScaleMin: Double = 0.5
    public static let viewportScaleMax: Double = 2.0
    public static let viewportBaseSize: Double = 600
    
    // MARK: - Canvas Rendering
    public static let lineWidthDefault: Double = 2
    public static let lineWidthTriangles: Double = 1.5
    public static let lineWidthTrianglesOuter: Double = 2
    public static let pointRadiusMin: Double = 1.5
    public static let pointRadiusBase: Double = 3
    public static let thicknessVariationBuckets: Int = 10
    public static let thicknessVariationBase: Double = 1
    public static let thicknessVariationRange: Double = 3
    
    // MARK: - Glow Effect Layers
    public struct GlowLayer: Sendable {
        public let width: Double
        public let opacity: Double
        
        public init(width: Double, opacity: Double) {
            self.width = width
            self.opacity = opacity
        }
    }
    
    public static let glowLayersNormal: [GlowLayer] = [
        GlowLayer(width: 12, opacity: 0.1),
        GlowLayer(width: 8, opacity: 0.15),
        GlowLayer(width: 5, opacity: 0.2)
    ]
    
    public static let glowLayersPerformance: [GlowLayer] = [
        GlowLayer(width: 8, opacity: 0.2)
    ]
    
    // MARK: - Mathematical Constants
    public static let phi: Double = (1 + sqrt(5)) / 2  // Golden ratio ≈ 1.618
    public static let goldenAngle: Double = .pi * (3 - sqrt(5))  // ≈ 137.5° in radians
}

