#if os(tvOS)
import SwiftUI
import UzumakiCore

/// Simplified view model for tvOS spiral visualizer
/// Optimized for Siri Remote navigation and large screen display
@Observable
@MainActor
public final class TVSpiralViewModel {

    // MARK: - Spiral Parameters

    public var spiralType: SpiralType = .archimedean {
        didSet {
            zoom = spiralType.defaultZoom
            invalidateCachedPoints()
        }
    }

    public var spinRate: Double = 0.5 {
        didSet { invalidateCachedPoints() }
    }
    public var tightness: Double = 3.0 {
        didSet { invalidateCachedPoints() }
    }
    public var stepSize: Double = 0.1 {
        didSet { invalidateCachedPoints() }
    }
    private var baseNumSteps: Int = 800 {
        didSet { invalidateCachedPoints() }
    }

    /// Effective number of steps (respects high quality mode)
    public var numSteps: Int {
        get { highQualityMode ? baseNumSteps : min(baseNumSteps, Constants.numStepsPerformanceMax) }
        set { baseNumSteps = newValue }
    }

    // MARK: - Appearance

    public var colorPreset: ColorPreset = .rainbow
    public var lineStyle: LineStyle = .solid

    // MARK: - Viewport

    public var zoom: Double = 1.0 {
        didSet { invalidateCachedPoints() }
    }

    // MARK: - Animation State

    public var time: Double = 0
    public var isPaused: Bool = false

    // TV screen is large, use appropriate viewport scale
    private let viewportScale: Double = 1.2

    // MARK: - UI State

    public var showingSettings: Bool = false
    public var showingPresets: Bool = false

    // MARK: - High Quality Mode

    /// When enabled, uses full detail. When disabled, limits to 500 points for smoother performance.
    /// Defaults to enabled on high-performance devices (Apple TV 4K).
    public var highQualityMode: Bool = TVSpiralViewModel.detectHighPerformanceDevice() {
        didSet { invalidateCachedPoints() }
    }

    /// Detects if device is high-performance (Apple TV 4K vs HD)
    private static func detectHighPerformanceDevice() -> Bool {
        var size = 0
        sysctlbyname("hw.machine", nil, &size, nil, 0)
        var machine = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.machine", &machine, &size, nil, 0)
        let model = String(cString: machine)
        // Apple TV 4K models: AppleTV6,2 (4K 1st gen), AppleTV11,1 (4K 2nd gen), AppleTV14,1 (4K 3rd gen)
        // Apple TV HD: AppleTV5,3
        return model.contains("AppleTV6") || model.contains("AppleTV11") || model.contains("AppleTV14")
    }

    // MARK: - Dim Mode

    /// When enabled, reduces brightness after extended viewing periods
    public var dimModeEnabled: Bool = false

    /// Current brightness multiplier (0.0 to 1.0)
    public private(set) var currentBrightness: Double = 1.0

    /// Time in seconds before dimming starts
    public var dimModeDelaySeconds: Double = 300 // 5 minutes

    /// Target brightness when dimmed (0.0 to 1.0)
    public var dimModeBrightness: Double = 0.5

    /// Tracks total viewing time for dim mode
    private var viewingStartTime: Date = Date()

    /// Whether currently in dimmed state
    public private(set) var isDimmed: Bool = false

    // MARK: - Auto-Cycle Presets

    /// When enabled, automatically cycles through presets
    public var autoCycleEnabled: Bool = false {
        didSet {
            if autoCycleEnabled {
                startAutoCycle()
            } else {
                stopAutoCycle()
            }
        }
    }

    /// Interval in seconds between preset changes
    public var autoCycleIntervalSeconds: Double = 30

    /// Current preset index for auto-cycling
    private var currentPresetIndex: Int = 0

    /// Task for auto-cycling
    private var autoCycleTask: Task<Void, Never>?

    // MARK: - Performance Tracking

    public private(set) var fps: Int = 0
    private var frameCount: Int = 0
    private var lastFPSUpdate: Date = Date()

    // MARK: - Cached Spiral Points

    private var cachedPoints: SpiralPoints?
    private var cachedTime: Double = -1
    private var needsPointsUpdate: Bool = true

    // MARK: - Computed Properties

    /// Current parameters as a struct for spiral generation
    public var params: SpiralParams {
        SpiralParams(
            type: spiralType,
            tightness: tightness,
            spinRate: spinRate,
            stepSize: stepSize,
            numSteps: numSteps,
            time: time,
            viewportScale: viewportScale,
            zoom: zoom,
            panX: 0,
            panY: 0,
            colorPreset: colorPreset,
            lineStyle: lineStyle,
            backgroundTheme: .dark,
            performanceMode: !highQualityMode,
            lineThicknessVariation: false,
            isPaused: isPaused
        )
    }

    /// Generate or return cached spiral points for current parameters
    public var spiralPoints: SpiralPoints {
        if needsPointsUpdate || cachedTime != time {
            cachedPoints = SpiralGenerator.generate(params: params)
            cachedTime = time
            needsPointsUpdate = false
        }
        return cachedPoints ?? SpiralPoints(capacity: 0)
    }

    /// Colors for the current preset
    public var colors: [Color] {
        colorPreset.colors
    }

    /// Glow color
    public var glowColor: Color {
        colors.count > 2 ? colors[2] : colors[0]
    }

    /// Background color
    public var backgroundColor: Color {
        Color.black
    }

    // MARK: - Initialization

    public init() {}

    // MARK: - Cache Management

    private func invalidateCachedPoints() {
        needsPointsUpdate = true
    }

    // MARK: - FPS Tracking

    /// Update FPS counter - call this each frame
    public func updateFPS() {
        frameCount += 1
        let now = Date()
        let elapsed = now.timeIntervalSince(lastFPSUpdate)

        if elapsed >= 1.0 {
            fps = Int(Double(frameCount) / elapsed)
            frameCount = 0
            lastFPSUpdate = now
        }
    }

    // MARK: - Actions

    /// Toggle play/pause
    public func togglePause() {
        isPaused.toggle()
    }

    /// Cycle to next spiral type
    public func nextSpiralType() {
        let allTypes = SpiralType.allCases
        if let currentIndex = allTypes.firstIndex(of: spiralType) {
            let nextIndex = (currentIndex + 1) % allTypes.count
            spiralType = allTypes[nextIndex]
        }
    }

    /// Cycle to previous spiral type
    public func previousSpiralType() {
        let allTypes = SpiralType.allCases
        if let currentIndex = allTypes.firstIndex(of: spiralType) {
            let previousIndex = (currentIndex - 1 + allTypes.count) % allTypes.count
            spiralType = allTypes[previousIndex]
        }
    }

    /// Cycle to next color preset
    public func nextColorPreset() {
        let allPresets = ColorPreset.allCases
        if let currentIndex = allPresets.firstIndex(of: colorPreset) {
            let nextIndex = (currentIndex + 1) % allPresets.count
            colorPreset = allPresets[nextIndex]
        }
    }

    /// Cycle to previous color preset
    public func previousColorPreset() {
        let allPresets = ColorPreset.allCases
        if let currentIndex = allPresets.firstIndex(of: colorPreset) {
            let previousIndex = (currentIndex - 1 + allPresets.count) % allPresets.count
            colorPreset = allPresets[previousIndex]
        }
    }

    /// Cycle to next line style
    public func nextLineStyle() {
        let allStyles = LineStyle.allCases
        if let currentIndex = allStyles.firstIndex(of: lineStyle) {
            let nextIndex = (currentIndex + 1) % allStyles.count
            lineStyle = allStyles[nextIndex]
        }
    }

    /// Adjust zoom
    public func adjustZoom(by delta: Double) {
        zoom = max(0.5, min(5.0, zoom + delta))
    }

    /// Adjust spin rate
    public func adjustSpinRate(by delta: Double) {
        spinRate = max(0.1, min(2.0, spinRate + delta))
    }

    /// Adjust tightness
    public func adjustTightness(by delta: Double) {
        tightness = max(Constants.tightnessMin, min(Constants.tightnessMax, tightness + delta))
        invalidateCachedPoints()
    }

    /// Load a preset
    public func loadPreset(_ preset: SpiralPreset) {
        spiralType = preset.type
        tightness = preset.tightness
        spinRate = preset.spinRate
        stepSize = preset.stepSize
        baseNumSteps = min(preset.numSteps, 1000)
        colorPreset = preset.colorPreset
        lineStyle = preset.lineStyle
        zoom = preset.zoom
        invalidateCachedPoints()
    }

    /// Increment time for animation
    public func incrementTime(delta: Double) {
        guard !isPaused else { return }
        time += delta

        // Update dim mode state
        updateDimMode()
    }

    /// Reset to defaults
    public func reset() {
        spiralType = .archimedean
        spinRate = 0.5
        tightness = 3.0
        stepSize = 0.1
        baseNumSteps = 800
        colorPreset = .rainbow
        lineStyle = .solid
        zoom = spiralType.defaultZoom
        time = 0
        isPaused = false
        highQualityMode = TVSpiralViewModel.detectHighPerformanceDevice()
        dimModeEnabled = false
        autoCycleEnabled = false
        resetDimMode()
        invalidateCachedPoints()
    }

    // MARK: - Auto-Cycle Methods

    /// Start auto-cycling through presets
    private func startAutoCycle() {
        stopAutoCycle()

        // Find current preset index if matching
        if let index = SpiralPreset.allPresets.firstIndex(where: { $0.type == spiralType }) {
            currentPresetIndex = index
        } else {
            currentPresetIndex = 0
        }

        autoCycleTask = Task {
            while !Task.isCancelled && autoCycleEnabled {
                try? await Task.sleep(for: .seconds(autoCycleIntervalSeconds))

                if !Task.isCancelled && autoCycleEnabled {
                    await MainActor.run {
                        nextPreset()
                    }
                }
            }
        }
    }

    /// Stop auto-cycling
    private func stopAutoCycle() {
        autoCycleTask?.cancel()
        autoCycleTask = nil
    }

    /// Cycle to next preset
    public func nextPreset() {
        let allPresets = SpiralPreset.allPresets
        currentPresetIndex = (currentPresetIndex + 1) % allPresets.count
        loadPreset(allPresets[currentPresetIndex])
    }

    /// Cycle to previous preset
    public func previousPreset() {
        let allPresets = SpiralPreset.allPresets
        currentPresetIndex = (currentPresetIndex - 1 + allPresets.count) % allPresets.count
        loadPreset(allPresets[currentPresetIndex])
    }

    // MARK: - Dim Mode Methods

    /// Update dim mode based on viewing time
    private func updateDimMode() {
        guard dimModeEnabled else {
            if isDimmed {
                resetDimMode()
            }
            return
        }

        let viewingTime = Date().timeIntervalSince(viewingStartTime)

        if viewingTime >= dimModeDelaySeconds && !isDimmed {
            // Start dimming
            isDimmed = true
            withAnimation(.easeInOut(duration: 2.0)) {
                currentBrightness = dimModeBrightness
            }
        }
    }

    /// Reset dim mode (e.g., on user interaction)
    public func resetDimMode() {
        viewingStartTime = Date()
        isDimmed = false
        withAnimation(.easeInOut(duration: 0.5)) {
            currentBrightness = 1.0
        }
    }

    /// Called when user interacts - resets dim timer
    public func userDidInteract() {
        resetDimMode()
    }

    // MARK: - Cleanup

    /// Clean up resources when view disappears
    public func cleanup() {
        stopAutoCycle()
    }
}
#endif

