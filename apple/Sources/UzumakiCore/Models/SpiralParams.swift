import Foundation

/// Complete spiral parameters matching the web SpiralParams interface
public struct SpiralParams: Equatable, Sendable, Codable {
    // MARK: - Spiral Generation
    public var type: SpiralType
    public var tightness: Double      // Controls spacing between turns
    public var spinRate: Double       // Animation speed
    public var stepSize: Double       // Angle increment per point
    public var numSteps: Int          // Total number of points
    public var time: Double           // Current animation time
    public var viewportScale: Double  // Scale factor based on viewport size
    
    // MARK: - Viewport Transform
    public var zoom: Double
    public var panX: Double
    public var panY: Double
    
    // MARK: - Appearance
    public var colorPreset: ColorPreset
    public var lineStyle: LineStyle
    public var backgroundTheme: BackgroundTheme
    
    // MARK: - Options
    public var performanceMode: Bool
    public var lineThicknessVariation: Bool
    public var isPaused: Bool
    
    // MARK: - Initialization
    
    public init(
        type: SpiralType = .archimedean,
        tightness: Double = 3,
        spinRate: Double = 0.5,
        stepSize: Double = 0.1,
        numSteps: Int = 500,
        time: Double = 0,
        viewportScale: Double = 1,
        zoom: Double = 1,
        panX: Double = 0,
        panY: Double = 0,
        colorPreset: ColorPreset = .rainbow,
        lineStyle: LineStyle = .solid,
        backgroundTheme: BackgroundTheme = .dark,
        performanceMode: Bool = false,
        lineThicknessVariation: Bool = false,
        isPaused: Bool = false
    ) {
        self.type = type
        self.tightness = tightness
        self.spinRate = spinRate
        self.stepSize = stepSize
        self.numSteps = numSteps
        self.time = time
        self.viewportScale = viewportScale
        self.zoom = zoom
        self.panX = panX
        self.panY = panY
        self.colorPreset = colorPreset
        self.lineStyle = lineStyle
        self.backgroundTheme = backgroundTheme
        self.performanceMode = performanceMode
        self.lineThicknessVariation = lineThicknessVariation
        self.isPaused = isPaused
    }
    
    /// Default parameters
    public static let `default` = SpiralParams()
    
    /// Effective number of steps (reduced in performance mode)
    public var effectiveNumSteps: Int {
        performanceMode ? min(numSteps, Constants.numStepsPerformanceMax) : numSteps
    }
}

