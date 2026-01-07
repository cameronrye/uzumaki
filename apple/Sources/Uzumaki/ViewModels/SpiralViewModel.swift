import SwiftUI
import UzumakiCore
#if os(iOS)
import UIKit
#endif

/// Main view model for the spiral visualizer using the new Observable macro
@Observable
@MainActor
public final class SpiralViewModel {

    // MARK: - Spiral Parameters

    public var spiralType: SpiralType = .archimedean {
        didSet {
            zoom = spiralType.defaultZoom
            panX = 0
            panY = 0
            triggerSelectionFeedback()
            saveSettings()
        }
    }

    public var spinRate: Double = 0.5 {
        didSet { saveSettings() }
    }
    public var tightness: Double = 3.0 {
        didSet { saveSettings() }
    }
    public var stepSize: Double = 0.1 {
        didSet { saveSettings() }
    }
    public var numSteps: Int = 500 {
        didSet { saveSettings() }
    }

    // MARK: - Appearance

    public var colorPreset: ColorPreset = .rainbow {
        didSet { saveSettings() }
    }
    public var lineStyle: LineStyle = .solid {
        didSet { saveSettings() }
    }
    public var backgroundTheme: BackgroundTheme = .dark {
        didSet { saveSettings() }
    }

    // MARK: - Options

    public var performanceMode: Bool = false {
        didSet { saveSettings() }
    }
    public var lineThicknessVariation: Bool = false {
        didSet { saveSettings() }
    }
    
    // MARK: - Viewport
    
    public var zoom: Double = 1.0
    public var panX: Double = 0
    public var panY: Double = 0
    
    // MARK: - Animation State

    public var time: Double = 0
    public var isPaused: Bool = false
    public var viewportScale: Double = 1.0
    public var fps: Int = 0

    // FPS calculation (not observable)
    private var frameCount: Int = 0
    private var lastFPSUpdate: Double = 0

    // Cached spiral points for performance
    private var cachedSpiralPoints: SpiralPoints?
    private var cachedSpiralParamsHash: Int = 0

    // MARK: - UI State

    public var showOnboarding: Bool = true
    public var showShortcuts: Bool = false
    public var toastMessage: String?
    
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
            panX: panX,
            panY: panY,
            colorPreset: colorPreset,
            lineStyle: lineStyle,
            backgroundTheme: backgroundTheme,
            performanceMode: performanceMode,
            lineThicknessVariation: lineThicknessVariation,
            isPaused: isPaused
        )
    }
    
    /// Generate spiral points for current parameters (cached for performance)
    public var spiralPoints: SpiralPoints {
        // Create a hash of parameters that affect spiral shape
        let currentHash = spiralParamsHash

        // Return cached points if parameters haven't changed
        if let cached = cachedSpiralPoints, cachedSpiralParamsHash == currentHash {
            return cached
        }

        // Generate new points and cache them
        let points = SpiralGenerator.generate(params: params)
        cachedSpiralPoints = points
        cachedSpiralParamsHash = currentHash
        return points
    }

    /// Hash of parameters that affect spiral geometry (excludes pan/zoom/isPaused)
    private var spiralParamsHash: Int {
        var hasher = Hasher()
        hasher.combine(spiralType)
        hasher.combine(tightness)
        hasher.combine(spinRate)
        hasher.combine(stepSize)
        hasher.combine(numSteps)
        hasher.combine(time)
        hasher.combine(viewportScale)
        hasher.combine(zoom)
        hasher.combine(panX)
        hasher.combine(panY)
        return hasher.finalize()
    }
    
    /// Colors for the current preset
    public var colors: [Color] {
        colorPreset.colors
    }
    
    /// Glow color (third color or first)
    public var glowColor: Color {
        colors.count > 2 ? colors[2] : colors[0]
    }
    
    /// Background color based on style and color preset
    public var backgroundColor: Color {
        if backgroundTheme == .matching {
            return colors[0].opacity(0.13)
        }
        return backgroundTheme.baseColor
    }
    
    // MARK: - Initialization

    public init() {
        loadSettings()
    }

    // MARK: - Persistence

    /// Flag to prevent saving while loading
    private var isLoadingSettings = false

    /// Check if app is launched in screenshot mode (should reset to defaults)
    private var isScreenshotMode: Bool {
        ProcessInfo.processInfo.arguments.contains("-RESET_FOR_SCREENSHOTS")
    }

    /// Load saved settings from UserDefaults
    private func loadSettings() {
        // In screenshot mode, always use defaults (don't load saved state)
        // This ensures consistent screenshots regardless of simulator state
        if isScreenshotMode {
            return
        }

        isLoadingSettings = true
        defer { isLoadingSettings = false }

        let settings = UserSettings.shared

        // Only load if user has launched before (otherwise use defaults)
        guard settings.hasLaunchedBefore else {
            settings.hasLaunchedBefore = true
            return
        }

        spiralType = settings.spiralType
        colorPreset = settings.colorPreset
        lineStyle = settings.lineStyle
        backgroundTheme = settings.backgroundTheme
        performanceMode = settings.performanceMode
        lineThicknessVariation = settings.lineThicknessVariation
        spinRate = settings.spinRate
        tightness = settings.tightness
        stepSize = settings.stepSize
        numSteps = settings.numSteps

        // Reset zoom to match loaded spiral type
        zoom = spiralType.defaultZoom
    }

    /// Save current settings to UserDefaults
    private func saveSettings() {
        // Don't save while loading or in screenshot mode
        guard !isLoadingSettings, !isScreenshotMode else { return }

        let settings = UserSettings.shared
        settings.spiralType = spiralType
        settings.colorPreset = colorPreset
        settings.lineStyle = lineStyle
        settings.backgroundTheme = backgroundTheme
        settings.performanceMode = performanceMode
        settings.lineThicknessVariation = lineThicknessVariation
        settings.spinRate = spinRate
        settings.tightness = tightness
        settings.stepSize = stepSize
        settings.numSteps = numSteps
    }

    // MARK: - Actions

    /// Toggle play/pause
    public func togglePause() {
        isPaused.toggle()
        triggerImpactFeedback(style: .light)
    }

    /// Reset to default values
    public func reset() {
        spiralType = .archimedean
        spinRate = 0.5
        tightness = 3.0
        stepSize = 0.1
        numSteps = 500
        colorPreset = .rainbow
        lineStyle = .solid
        backgroundTheme = .dark
        performanceMode = false
        lineThicknessVariation = false
        zoom = spiralType.defaultZoom
        panX = 0
        panY = 0
        time = 0
        isPaused = false
        triggerImpactFeedback(style: .medium)
    }
    
    /// Load a preset
    public func loadPreset(_ preset: SpiralPreset) {
        spiralType = preset.type
        tightness = preset.tightness
        spinRate = preset.spinRate
        stepSize = preset.stepSize
        numSteps = preset.numSteps
        colorPreset = preset.colorPreset
        lineStyle = preset.lineStyle
        zoom = preset.zoom
        panX = 0
        panY = 0
    }
    
    /// Increment time for animation
    public func incrementTime(delta: Double) {
        // Update FPS counter
        frameCount += 1
        lastFPSUpdate += delta
        if lastFPSUpdate >= 1.0 {
            fps = frameCount
            frameCount = 0
            lastFPSUpdate = 0
        }

        guard !isPaused else { return }
        time += delta
    }
    
    /// Adjust spin rate within bounds
    public func adjustSpinRate(by delta: Double) {
        spinRate = max(Constants.spinRateMin, min(Constants.spinRateMax, spinRate + delta))
    }
    
    /// Show a toast message (auto-dismisses after timeout)
    public func showToast(_ message: String) {
        toastMessage = message

        // Auto-dismiss after duration
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(Constants.toastDurationSeconds))
            // Only dismiss if the message hasn't changed
            if toastMessage == message {
                withAnimation {
                    toastMessage = nil
                }
            }
        }
    }

    /// Dismiss the toast immediately
    public func dismissToast() {
        withAnimation {
            toastMessage = nil
        }
    }

    /// Update viewport scale based on canvas size
    public func updateViewportScale(for size: CGSize) {
        let minDimension = min(size.width, size.height)
        let scale = max(
            Constants.viewportScaleMin,
            min(Constants.viewportScaleMax, minDimension / Constants.viewportBaseSize)
        )
        viewportScale = scale
    }

    // MARK: - Haptic Feedback

    /// Trigger selection changed haptic (for picker changes)
    public func triggerSelectionFeedback() {
        #if os(iOS)
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
        #endif
    }

    /// Trigger impact haptic (for button taps)
    public func triggerImpactFeedback(style: ImpactStyle = .light) {
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: style.uiKitStyle)
        generator.impactOccurred()
        #endif
    }

    /// Trigger success haptic (for completed actions)
    public func triggerSuccessFeedback() {
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        #endif
    }
}

// MARK: - Impact Style Helper

public enum ImpactStyle {
    case light, medium, heavy

    #if os(iOS)
    var uiKitStyle: UIImpactFeedbackGenerator.FeedbackStyle {
        switch self {
        case .light: return .light
        case .medium: return .medium
        case .heavy: return .heavy
        }
    }
    #endif
}
