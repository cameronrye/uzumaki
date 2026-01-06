#if os(iOS) || os(macOS)
import SwiftUI
import UzumakiCore
#if os(iOS)
import UIKit
#endif

// MARK: - Cross-Platform Hover Effect

extension View {
    /// Applies hover effect on iOS (for trackpad/mouse), no-op on macOS
    @ViewBuilder
    func adaptiveHoverEffect() -> some View {
        #if os(iOS)
        self.hoverEffect(.lift)
        #else
        self
        #endif
    }
}

/// Main content view for the Uzumaki app
public struct ContentView: View {
    @State private var viewModel = SpiralViewModel()

    // Gesture state
    @State private var currentZoom: Double = 1.0
    @State private var currentPan: CGSize = .zero
    @State private var showOnboardingHint: Bool = true

    // Enhanced gesture tracking
    @State private var lastMagnification: CGFloat = 1.0
    @State private var canvasSize: CGSize = .zero
    @State private var hitZoomBoundary: Bool = false
    @State private var isGestureActive: Bool = false

    // Gesture start state tracking - captured at gesture begin to prevent drift
    @State private var gestureStartPan: CGSize = .zero
    @State private var isPanGestureActive: Bool = false
    @State private var pinchCenter: CGPoint? = nil

    // Pre-prepared haptic generators for lower latency (iOS only)
    #if os(iOS)
    @State private var lightImpactGenerator = UIImpactFeedbackGenerator(style: .light)
    @State private var mediumImpactGenerator = UIImpactFeedbackGenerator(style: .medium)
    #endif

    // Permission alert state
    @State private var showPhotoPermissionAlert: Bool = false

    // Environment for reduced motion and horizontal size class
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    /// Whether to use iPad landscape layout (side panel)
    private var useIPadLayout: Bool {
        #if os(iOS)
        return horizontalSizeClass == .regular && verticalSizeClass == .regular
        #else
        return false
        #endif
    }

    public init() {}

    public var body: some View {
        ZStack {
            // Background
            viewModel.backgroundColor
                .ignoresSafeArea()

            // Use iPad side panel layout or standard overlay layout
            if useIPadLayout {
                iPadLayout
            } else {
                standardLayout
            }

            // Toast (at top)
            if let message = viewModel.toastMessage {
                toastView(message: message)
            }
        }
        .onAppear {
            // Pause animation if user prefers reduced motion
            if reduceMotion {
                viewModel.isPaused = true
            }

            // Dismiss onboarding hint after a few seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                withAnimation(.easeOut(duration: 0.3)) {
                    showOnboardingHint = false
                }
            }
        }
        .onChange(of: reduceMotion) { _, newValue in
            // Continuously respect reduced motion preference
            if newValue {
                viewModel.isPaused = true
                viewModel.showToast("Animation paused (Reduce Motion enabled)")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Spiral Canvas")
        .accessibilityHint("Interactive spiral visualization. Use gestures to zoom and pan.")
        // Keyboard shortcuts for iOS (external keyboards) and macOS
        .background {
            keyboardShortcutButtons
        }
        #if os(macOS)
        .frame(minWidth: 800, minHeight: 600)
        .onReceive(NotificationCenter.default.publisher(for: .togglePause)) { _ in
            viewModel.togglePause()
        }
        .onReceive(NotificationCenter.default.publisher(for: .reset)) { _ in
            resetView()
        }
        .onReceive(NotificationCenter.default.publisher(for: .export)) { _ in
            exportSpiral()
        }
        #else
        .alert("Photo Library Access", isPresented: $showPhotoPermissionAlert) {
            Button("Open Settings") {
                ExportManager.openSettings()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Uzumaki needs access to your Photo Library to save spirals. Please enable access in Settings.")
        }
        #endif
    }

    // MARK: - Layout Views

    /// Standard overlay layout (iPhone and compact iPad)
    private var standardLayout: some View {
        ZStack {
            spiralCanvas

            // UI Overlay - wrapped in AdaptiveGlassContainer for iOS 26+
            AdaptiveGlassContainer {
                VStack {
                    Spacer()

                    // Gesture hint (first launch)
                    if showOnboardingHint {
                        gestureHint
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }

                    Spacer().frame(height: 8)

                    // Controls
                    ControlsView(viewModel: viewModel, onExport: exportSpiral, onShare: shareSpiral)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                }
            }
        }
    }

    /// iPad layout with side panel for controls
    private var iPadLayout: some View {
        HStack(spacing: 0) {
            // Main canvas area
            ZStack {
                spiralCanvas

                // Gesture hint (first launch)
                if showOnboardingHint {
                    VStack {
                        Spacer()
                        gestureHint
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                            .padding(.bottom, 20)
                    }
                }
            }

            // Side panel with controls
            iPadSidePanel
        }
    }

    /// iPad side panel with controls
    private var iPadSidePanel: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                HStack {
                    Text("Controls")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                    Spacer()
                }
                .padding(.bottom, 8)

                // Spiral type picker
                iPadSpiralTypePicker

                Divider().background(Color.white.opacity(0.1))

                // Parameter sliders
                iPadParameterSliders

                Divider().background(Color.white.opacity(0.1))

                // Appearance options
                iPadAppearanceSection

                Divider().background(Color.white.opacity(0.1))

                // Quick presets
                iPadPresetsSection

                Divider().background(Color.white.opacity(0.1))

                // Action buttons
                iPadActionButtons

                Spacer(minLength: 20)

                // Footer attribution
                iPadFooter
            }
            .padding(20)
        }
        .frame(width: 320)
        .background(Color.black.opacity(0.3))
        .background(.ultraThinMaterial)
    }

    /// Footer with attribution
    private var iPadFooter: some View {
        HStack(spacing: 4) {
            Text("Made with")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.5))

            Image(systemName: "heart.fill")
                .font(.caption2)
                .foregroundStyle(BrandColors.gradient)

            Text("by")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.5))

            Link("Cameron Rye", destination: URL(string: "https://rye.dev")!)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(.top, 8)
    }

    // MARK: - iPad Side Panel Components

    private var iPadSpiralTypePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Spiral Type")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.8))

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(SpiralType.allCases) { type in
                    Button(action: { viewModel.spiralType = type }) {
                        Text(type.displayName)
                            .font(.caption.weight(.medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(viewModel.spiralType == type ? Color.white.opacity(0.2) : Color.white.opacity(0.08))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(viewModel.spiralType == type ? Color.white.opacity(0.4) : Color.clear, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.white)
                    .adaptiveHoverEffect()
                }
            }
        }
    }

    private var iPadParameterSliders: some View {
        VStack(spacing: 12) {
            iPadSlider(label: "Animation Speed", value: $viewModel.spinRate, range: Constants.spinRateMin...Constants.spinRateMax, format: "%.2f")
            iPadSlider(label: "Spiral Density", value: $viewModel.tightness, range: Constants.tightnessMin...Constants.tightnessMax, format: "%.1f")
            iPadSlider(label: "Smoothness", value: $viewModel.stepSize, range: Constants.stepSizeMin...Constants.stepSizeMax, format: "%.2f")

            // Complexity slider (Int)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Complexity")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.white.opacity(0.8))
                    Spacer()
                    Text("\(viewModel.numSteps)")
                        .font(.caption.weight(.semibold).monospaced())
                        .foregroundStyle(.white.opacity(0.9))
                }
                Slider(
                    value: Binding(
                        get: { Double(viewModel.numSteps) },
                        set: { viewModel.numSteps = Int($0) }
                    ),
                    in: Double(Constants.numStepsMin)...Double(Constants.numStepsMax),
                    step: Double(Constants.numStepsStep)
                )
                .tint(.white.opacity(0.8))
            }
        }
    }

    private func iPadSlider(label: String, value: Binding<Double>, range: ClosedRange<Double>, format: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white.opacity(0.8))
                Spacer()
                Text(String(format: format, value.wrappedValue))
                    .font(.caption.weight(.semibold).monospaced())
                    .foregroundStyle(.white.opacity(0.9))
            }
            Slider(value: value, in: range)
                .tint(.white.opacity(0.8))
        }
    }

    private var iPadAppearanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Appearance")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.8))

            // Color preset
            iPadPickerRow(title: "Colors", selection: $viewModel.colorPreset) { preset in
                HStack(spacing: 2) {
                    ForEach(0..<min(3, preset.colors.count), id: \.self) { index in
                        Circle().fill(preset.colors[index]).frame(width: 8, height: 8)
                    }
                }
            }

            // Line style
            iPadPickerRow(title: "Line Style", selection: $viewModel.lineStyle) { _ in EmptyView() }

            // Background
            iPadPickerRow(title: "Background", selection: $viewModel.backgroundTheme) { _ in EmptyView() }

            // Toggles
            Toggle("Variable Thickness", isOn: $viewModel.lineThicknessVariation)
                .font(.caption.weight(.medium))
                .foregroundStyle(.white.opacity(0.8))
                .tint(.white.opacity(0.8))

            Toggle("Performance Mode", isOn: $viewModel.performanceMode)
                .font(.caption.weight(.medium))
                .foregroundStyle(.white.opacity(0.8))
                .tint(.white.opacity(0.8))
        }
    }

    private func iPadPickerRow<T: CaseIterable & Identifiable & RawRepresentable, Content: View>(
        title: String,
        selection: Binding<T>,
        @ViewBuilder preview: @escaping (T) -> Content
    ) -> some View where T.RawValue == String, T.AllCases: RandomAccessCollection {
        HStack {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(.white.opacity(0.8))
            Spacer()
            Menu {
                ForEach(Array(T.allCases), id: \.id) { item in
                    Button(action: { selection.wrappedValue = item }) {
                        Text(item.rawValue.capitalized)
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    preview(selection.wrappedValue)
                    Text(selection.wrappedValue.rawValue.capitalized)
                        .font(.caption.weight(.medium))
                    Image(systemName: "chevron.down")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .foregroundStyle(.white.opacity(0.9))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.1)))
            }
        }
    }

    private var iPadPresetsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Presets")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.8))

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(SpiralPreset.allPresets) { preset in
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            viewModel.loadPreset(preset)
                        }
                    }) {
                        HStack(spacing: 4) {
                            ForEach(0..<min(3, preset.colorPreset.colors.count), id: \.self) { index in
                                Circle().fill(preset.colorPreset.colors[index]).frame(width: 4, height: 4)
                            }
                            Text(preset.name)
                                .font(.caption2.weight(.medium))
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 6)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.08)))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.white.opacity(0.9))
                    .adaptiveHoverEffect()
                }
            }
        }
    }

    private var iPadActionButtons: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Play/Pause
                Button(action: viewModel.togglePause) {
                    Label(viewModel.isPaused ? "Play" : "Pause", systemImage: viewModel.isPaused ? "play.fill" : "pause.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.white.opacity(0.2))
                .foregroundStyle(.white)
                .adaptiveHoverEffect()

                // Reset
                Button(action: resetView) {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.white.opacity(0.2))
                .foregroundStyle(.white)
                .adaptiveHoverEffect()
            }

            HStack(spacing: 12) {
                // Export
                Button(action: exportSpiral) {
                    Label("Export", systemImage: "square.and.arrow.down")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.white.opacity(0.2))
                .foregroundStyle(.white)
                .adaptiveHoverEffect()

                // Share
                Button(action: shareSpiral) {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.white.opacity(0.2))
                .foregroundStyle(.white)
                .adaptiveHoverEffect()
            }
        }
    }

    // MARK: - Shared Components

    /// The spiral canvas with gestures
    private var spiralCanvas: some View {
        GeometryReader { geometry in
            ZStack {
                SpiralCanvasView(viewModel: viewModel)
                    .gesture(doubleTapGesture)
                    #if os(macOS)
                    // macOS: Use SwiftUI MagnificationGesture (works well with trackpad)
                    .gesture(combinedZoomPanGesture)
                    #endif

                #if os(iOS)
                // iOS: Use UIKit gesture recognizers for accurate touch tracking
                PinchGestureView(
                    onPinchChanged: { deltaScale, center in
                        handlePinchChanged(deltaScale: deltaScale, center: center)
                    },
                    onPinchEnded: {
                        handlePinchEnded()
                    },
                    onPanChanged: { translation in
                        handlePanChanged(translation: translation)
                    },
                    onPanEnded: { predictedTranslation in
                        handlePanEnded(predictedTranslation: predictedTranslation)
                    }
                )
                #endif
            }
            .onAppear {
                canvasSize = geometry.size
                viewModel.updateViewportScale(for: geometry.size)
                // Pre-prepare haptic generators for lower latency
                #if os(iOS)
                lightImpactGenerator.prepare()
                mediumImpactGenerator.prepare()
                #endif
            }
            .onChange(of: geometry.size) { _, newSize in
                canvasSize = newSize
                viewModel.updateViewportScale(for: newSize)
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Keyboard Shortcuts

    /// Hidden buttons that provide keyboard shortcuts on iOS with external keyboards
    @ViewBuilder
    private var keyboardShortcutButtons: some View {
        // Using a Group of hidden buttons to provide keyboard shortcuts
        Group {
            Button("") {
                viewModel.togglePause()
            }
            .keyboardShortcut(.space, modifiers: [])

            Button("") {
                resetView()
            }
            .keyboardShortcut("r", modifiers: [])

            Button("") {
                exportSpiral()
            }
            .keyboardShortcut("e", modifiers: [])
        }
        .buttonStyle(.plain)
        .frame(width: 0, height: 0)
        .opacity(0)
        .allowsHitTesting(false)
    }

    // MARK: - Gesture Hint

    private var gestureHint: some View {
        HStack(spacing: 16) {
            hintItem(icon: "hand.pinch", text: "Pinch to zoom")
            hintItem(icon: "hand.draw", text: "Drag to pan")
            hintItem(icon: "hand.tap", text: "Double-tap to reset")
        }
        .font(.caption.weight(.medium))
        .foregroundStyle(.white.opacity(0.7))
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .adaptiveGlassCapsule()
        .padding(.bottom, 8)
    }

    private func hintItem(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.footnote)
            Text(text)
        }
    }

    // MARK: - Toast

    private func toastView(message: String) -> some View {
        VStack {
            // Toast at top (Apple standard)
            Text(message)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .adaptiveGlassCapsule()
                .transition(.move(edge: .top).combined(with: .opacity))
                .padding(.top, 60)

            Spacer()
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: viewModel.toastMessage)
    }

    // MARK: - Gestures

    private var doubleTapGesture: some Gesture {
        TapGesture(count: 2)
            .onEnded {
                resetView()
            }
    }

    /// Combined zoom and pan gesture for simultaneous recognition (macOS only)
    private var combinedZoomPanGesture: some Gesture {
        SimultaneousGesture(zoomGesture, panGesture)
    }

    /// Zoom gesture for macOS trackpad (uses canvas center as anchor point)
    private var zoomGesture: some Gesture {
        MagnificationGesture()
            .onChanged { scale in
                // Cancel any ongoing momentum animation by snapping state
                cancelMomentumAndSyncState()
                isGestureActive = true

                // Calculate zoom delta from last magnification value
                let delta = scale / lastMagnification
                let proposedZoom = viewModel.zoom * delta
                let clampedZoom = max(Constants.zoomMin, min(Constants.zoomMax, proposedZoom))

                // For macOS trackpad, zoom around canvas center (no pinch center available)
                // This provides consistent, predictable behavior
                viewModel.zoom = clampedZoom
                lastMagnification = scale
            }
            .onEnded { _ in
                currentZoom = viewModel.zoom
                lastMagnification = 1.0
                hitZoomBoundary = false
                isGestureActive = false
                syncCurrentPan()
            }
    }

    /// Enhanced pan gesture with gesture-start tracking to prevent jumpy behavior
    private var panGesture: some Gesture {
        DragGesture(minimumDistance: 5) // Prevent accidental pan on tap
            .onChanged { value in
                // On first touch of this gesture, capture the starting state
                if !isPanGestureActive {
                    // Cancel any ongoing momentum animation
                    cancelMomentumAndSyncState()
                    // Capture pan state at gesture start
                    gestureStartPan = CGSize(width: viewModel.panX, height: viewModel.panY)
                    isPanGestureActive = true
                }

                isGestureActive = true

                // Scale pan speed by zoom level - move slower when zoomed in for precision
                let zoomScale = max(1.0, viewModel.zoom)
                let scaledTranslationX = value.translation.width / zoomScale
                let scaledTranslationY = value.translation.height / zoomScale

                // Calculate new pan from gesture START position (not currentPan which may be stale)
                let newPanX = gestureStartPan.width + scaledTranslationX
                let newPanY = gestureStartPan.height + scaledTranslationY

                // Apply dynamic bounds based on zoom level
                let maxPan = Constants.panLimit / viewModel.zoom
                viewModel.panX = max(-maxPan, min(maxPan, newPanX))
                viewModel.panY = max(-maxPan, min(maxPan, newPanY))
            }
            .onEnded { value in
                // Calculate momentum using predicted end translation
                let zoomScale = max(1.0, viewModel.zoom)
                let maxPan = Constants.panLimit / viewModel.zoom

                // Use predicted translation from gesture START position
                let predictedX = gestureStartPan.width + value.predictedEndTranslation.width / zoomScale
                let predictedY = gestureStartPan.height + value.predictedEndTranslation.height / zoomScale

                // Clamp to bounds
                let finalX = max(-maxPan, min(maxPan, predictedX))
                let finalY = max(-maxPan, min(maxPan, predictedY))

                // Animate to predicted position with deceleration
                withAnimation(.easeOut(duration: 0.3)) {
                    viewModel.panX = finalX
                    viewModel.panY = finalY
                }

                // Update state immediately (not after delay) to prevent jumpy behavior
                currentPan = CGSize(width: finalX, height: finalY)
                isPanGestureActive = false
                isGestureActive = false
            }
    }

    // MARK: - iOS Pinch Gesture Handlers

    #if os(iOS)
    /// Handle pinch gesture change from PinchGestureView
    private func handlePinchChanged(deltaScale: CGFloat, center: CGPoint) {
        // Cancel any ongoing momentum animation on first pinch
        if pinchCenter == nil {
            cancelMomentumAndSyncState()
            pinchCenter = center
        }

        isGestureActive = true

        let proposedZoom = viewModel.zoom * deltaScale
        let clampedZoom = max(Constants.zoomMin, min(Constants.zoomMax, proposedZoom))

        // Haptic feedback when hitting zoom boundaries
        if proposedZoom != clampedZoom && !hitZoomBoundary {
            lightImpactGenerator.impactOccurred()
            hitZoomBoundary = true
        } else if proposedZoom == clampedZoom {
            hitZoomBoundary = false
        }

        // Anchor zoom to the initial pinch center point
        // This keeps the point under the user's fingers stable during zoom
        if let anchorPoint = pinchCenter, canvasSize != .zero {
            let centerX = canvasSize.width / 2
            let centerY = canvasSize.height / 2

            // Calculate offset from canvas center to pinch point
            let offsetX = anchorPoint.x - centerX
            let offsetY = anchorPoint.y - centerY

            // Adjust pan to compensate for zoom change around pinch point
            let zoomRatio = clampedZoom / viewModel.zoom
            let panAdjustX = offsetX * (1 - zoomRatio)
            let panAdjustY = offsetY * (1 - zoomRatio)

            viewModel.panX += panAdjustX
            viewModel.panY += panAdjustY
        }

        viewModel.zoom = clampedZoom
    }

    /// Handle pinch gesture end from PinchGestureView
    private func handlePinchEnded() {
        currentZoom = viewModel.zoom
        hitZoomBoundary = false
        pinchCenter = nil
        isGestureActive = false
        syncCurrentPan()
    }

    /// Handle pan gesture change from PinchGestureView
    private func handlePanChanged(translation: CGSize) {
        // On first touch of this gesture, capture the starting state
        if !isPanGestureActive {
            // Cancel any ongoing momentum animation
            cancelMomentumAndSyncState()
            // Capture pan state at gesture start
            gestureStartPan = CGSize(width: viewModel.panX, height: viewModel.panY)
            isPanGestureActive = true
        }

        isGestureActive = true

        // Scale pan speed by zoom level - move slower when zoomed in for precision
        let zoomScale = max(1.0, viewModel.zoom)
        let scaledTranslationX = translation.width / zoomScale
        let scaledTranslationY = translation.height / zoomScale

        // Calculate new pan from gesture START position (not currentPan which may be stale)
        let newPanX = gestureStartPan.width + scaledTranslationX
        let newPanY = gestureStartPan.height + scaledTranslationY

        // Apply dynamic bounds based on zoom level
        let maxPan = Constants.panLimit / viewModel.zoom
        viewModel.panX = max(-maxPan, min(maxPan, newPanX))
        viewModel.panY = max(-maxPan, min(maxPan, newPanY))
    }

    /// Handle pan gesture end from PinchGestureView
    private func handlePanEnded(predictedTranslation: CGSize) {
        let zoomScale = max(1.0, viewModel.zoom)
        let maxPan = Constants.panLimit / viewModel.zoom

        // Use predicted translation from gesture START position
        let predictedX = gestureStartPan.width + predictedTranslation.width / zoomScale
        let predictedY = gestureStartPan.height + predictedTranslation.height / zoomScale

        // Clamp to bounds
        let finalX = max(-maxPan, min(maxPan, predictedX))
        let finalY = max(-maxPan, min(maxPan, predictedY))

        // Animate to predicted position with deceleration
        withAnimation(.easeOut(duration: 0.3)) {
            viewModel.panX = finalX
            viewModel.panY = finalY
        }

        // Update state immediately (not after delay) to prevent jumpy behavior
        currentPan = CGSize(width: finalX, height: finalY)
        isPanGestureActive = false
        isGestureActive = false
    }
    #endif

    // MARK: - Gesture State Helpers

    /// Cancel any ongoing momentum animation and sync state
    private func cancelMomentumAndSyncState() {
        // Reading and immediately writing the same value cancels any ongoing animation
        viewModel.panX = viewModel.panX
        viewModel.panY = viewModel.panY
        syncCurrentPan()
    }

    /// Sync currentPan with viewModel values
    private func syncCurrentPan() {
        currentPan = CGSize(width: viewModel.panX, height: viewModel.panY)
    }

    // MARK: - Actions

    private func resetView() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            viewModel.zoom = viewModel.spiralType.defaultZoom
            viewModel.panX = 0
            viewModel.panY = 0
            currentZoom = viewModel.zoom
            currentPan = .zero
        }
        // Reset gesture tracking state
        gestureStartPan = .zero
        isPanGestureActive = false
        pinchCenter = nil
        #if os(iOS)
        // Haptic feedback using pre-prepared generator for lower latency
        mediumImpactGenerator.impactOccurred()
        mediumImpactGenerator.prepare() // Re-prepare for next use
        #endif
    }

    // MARK: - Export

    private func exportSpiral() {
        Task {
            if #available(macOS 14.0, iOS 17.0, *) {
                do {
                    let data = try await ExportManager.exportAsPNG(viewModel: viewModel)
                    #if os(macOS)
                    do {
                        try await ExportManager.savePNG(data: data)
                        viewModel.showToast("Spiral exported!")
                        viewModel.triggerSuccessFeedback()
                    } catch ExportError.saveCancelled {
                        // User cancelled, no need to show error
                    } catch {
                        viewModel.showToast(error.localizedDescription)
                    }
                    #else
                    // On iOS, save to Photos
                    let result = await ExportManager.saveToPhotos(data: data)
                    switch result {
                    case .success:
                        viewModel.showToast("Saved to Photos!")
                        viewModel.triggerSuccessFeedback()
                    case .permissionDenied:
                        showPhotoPermissionAlert = true
                    case .failed(let error):
                        let message = error?.localizedDescription ?? "Unknown error"
                        viewModel.showToast("Could not save: \(message)")
                    }
                    #endif
                } catch {
                    viewModel.showToast(error.localizedDescription)
                }
            } else {
                viewModel.showToast("Export requires iOS 17+ / macOS 14+")
            }
        }
    }

    private func shareSpiral() {
        Task {
            if #available(macOS 14.0, iOS 17.0, *) {
                do {
                    let data = try await ExportManager.exportAsPNG(viewModel: viewModel)
                    #if os(iOS)
                    ExportManager.share(data: data)
                    #else
                    ExportManager.share(data: data)
                    #endif
                } catch {
                    viewModel.showToast(error.localizedDescription)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
#endif  // os(iOS) || os(macOS)
