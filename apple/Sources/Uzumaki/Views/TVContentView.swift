#if os(tvOS)
import SwiftUI
import GameController
import UzumakiCore

/// Main content view for tvOS
/// Uses focus-based navigation and Siri Remote gestures
public struct TVContentView: View {
    @State private var viewModel = TVSpiralViewModel()
    @State private var showControls = true
    @State private var controlsTimer: Task<Void, Never>?
    @State private var navigationPath = NavigationPath()
    @FocusState private var focusedControl: TVControl?

    // Touch surface gesture tracking
    @State private var touchStartPosition: CGPoint = .zero
    @State private var lastTouchPosition: CGPoint = .zero
    @State private var isTouchActive: Bool = false

    public init() {}

    public var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                // Background with brightness modifier for dim mode
                viewModel.backgroundColor
                    .brightness(viewModel.currentBrightness - 1.0)
                    .ignoresSafeArea()

                // Spiral Canvas with brightness modifier
                TVSpiralCanvasView(viewModel: viewModel)
                    .brightness(viewModel.currentBrightness - 1.0)
                    .ignoresSafeArea()

                // Touch surface gesture overlay (when controls hidden)
                if !showControls {
                    TVTouchSurfaceGestureView(
                        onSwipeLeft: {
                            viewModel.userDidInteract()
                            viewModel.previousPreset()
                        },
                        onSwipeRight: {
                            viewModel.userDidInteract()
                            viewModel.nextPreset()
                        },
                        onSwipeUp: {
                            viewModel.userDidInteract()
                            viewModel.adjustZoom(by: 0.3)
                        },
                        onSwipeDown: {
                            viewModel.userDidInteract()
                            viewModel.adjustZoom(by: -0.3)
                        },
                        onTouchPositionChanged: { position in
                            viewModel.userDidInteract()
                            handleTouchPosition(position)
                        }
                    )
                    .ignoresSafeArea()
                }

                // Controls Overlay
                if showControls {
                    controlsOverlay
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }

                // Status indicator (when controls hidden)
                if !showControls {
                    statusIndicator
                        .transition(.opacity)
                }
            }
            .navigationDestination(for: TVDestination.self) { destination in
                switch destination {
                case .settings:
                    TVSettingsView(viewModel: viewModel)
                case .presets:
                    TVPresetsView(viewModel: viewModel)
                }
            }
        }
        .onPlayPauseCommand {
            viewModel.userDidInteract()
            viewModel.togglePause()
            showControlsTemporarily()
        }
        .onExitCommand {
            viewModel.userDidInteract()
            // Menu button: toggle controls visibility
            withAnimation(.easeOut(duration: 0.25)) {
                showControls.toggle()
            }
            if showControls {
                resetControlsTimer()
            }
        }
        .onAppear {
            // Set initial focus to play/pause button
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                focusedControl = .playPause
            }
            // Start timer to auto-hide controls after initial exploration
            resetControlsTimer()
            // Setup game controller notifications for touch surface
            setupGameControllerNotifications()
        }
        .onDisappear {
            // Clean up timer task and view model resources
            controlsTimer?.cancel()
            controlsTimer = nil
            viewModel.cleanup()
        }
        .onChange(of: focusedControl) { _, _ in
            viewModel.userDidInteract()
            // Reset timer when user navigates between controls
            if showControls {
                resetControlsTimer()
            }
        }
        .onOpenURL { url in
            // Handle deep link from Top Shelf directly
            // URL format: uzumaki://preset/{preset-id}
            handleDeepLink(url: url)
        }
    }

    // MARK: - Deep Link Handling

    /// Handle deep links from Top Shelf selections
    /// URL format: uzumaki://preset/{preset-id}
    private func handleDeepLink(url: URL) {
        guard url.scheme == "uzumaki",
              url.host == "preset",
              let presetId = url.pathComponents.dropFirst().first,
              let preset = SpiralPreset.allPresets.first(where: { $0.id == presetId }) else {
            return
        }

        viewModel.loadPreset(preset)
        showControlsTemporarily()
    }

    // MARK: - Touch Surface Handling

    /// Handle normalized touch position (0-1 range) for spiral parameter adjustment
    private func handleTouchPosition(_ position: CGPoint) {
        // Map X position to spin rate (0.1 to 2.0)
        let newSpinRate = 0.1 + (position.x * 1.9)
        viewModel.spinRate = newSpinRate

        // Map Y position to tightness (inverted: top = high, bottom = low)
        let newTightness = Constants.tightnessMin + ((1.0 - position.y) * (Constants.tightnessMax - Constants.tightnessMin))
        viewModel.tightness = newTightness
    }

    /// Setup game controller notifications for Siri Remote touch surface
    private func setupGameControllerNotifications() {
        NotificationCenter.default.addObserver(
            forName: .GCControllerDidConnect,
            object: nil,
            queue: .main
        ) { notification in
            // Configure the controller directly on main queue (already on main due to queue: .main)
            if let controller = notification.object as? GCController,
               let microGamepad = controller.microGamepad {
                microGamepad.reportsAbsoluteDpadValues = true
                microGamepad.allowsRotation = true
            }
        }

        // Setup for already connected controllers
        for controller in GCController.controllers() {
            setupTouchSurface(for: controller)
        }
    }

    /// Setup touch surface input handling for a controller
    private func setupTouchSurface(for controller: GCController) {
        guard let microGamepad = controller.microGamepad else { return }

        // Enable touch surface absolute position tracking
        microGamepad.reportsAbsoluteDpadValues = true

        microGamepad.dpad.valueChangedHandler = { [self] _, xValue, yValue in
            guard !showControls else { return }

            // Normalize to 0-1 range (dpad reports -1 to 1)
            let normalizedX = (Double(xValue) + 1.0) / 2.0
            let normalizedY = (Double(yValue) + 1.0) / 2.0

            Task { @MainActor in
                handleTouchPosition(CGPoint(x: normalizedX, y: normalizedY))
            }
        }
    }

    // MARK: - Status Indicator (when controls hidden)

    private var statusIndicator: some View {
        VStack {
            HStack {
                // Hint to show controls and swipe gestures
                VStack(alignment: .leading, spacing: 4) {
                    Label("Press Menu for controls", systemImage: "tv.and.mediabox")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                    Label("Swipe to change presets", systemImage: "hand.draw")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.4))
                }
                .padding(20)

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    if viewModel.isPaused {
                        Label("Paused", systemImage: "pause.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    if viewModel.autoCycleEnabled {
                        Label("Auto-Cycle", systemImage: "arrow.triangle.2.circlepath")
                            .font(.caption)
                            .foregroundStyle(.cyan.opacity(0.7))
                    }
                    if viewModel.highQualityMode {
                        Label("High Quality", systemImage: "sparkles")
                            .font(.caption)
                            .foregroundStyle(.green.opacity(0.7))
                    }
                    if viewModel.isDimmed {
                        Label("Dimmed", systemImage: "moon.fill")
                            .font(.caption)
                            .foregroundStyle(.purple.opacity(0.7))
                    }
                    Text("\(viewModel.fps) FPS")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.white.opacity(0.4))
                }
                .padding(20)
            }
            Spacer()
        }
        .focusable()
        .onMoveCommand { direction in
            viewModel.userDidInteract()
            // When controls hidden, use D-pad to cycle presets or adjust zoom
            switch direction {
            case .left:
                viewModel.previousPreset()
            case .right:
                viewModel.nextPreset()
            case .up:
                viewModel.adjustZoom(by: 0.2)
            case .down:
                viewModel.adjustZoom(by: -0.2)
            @unknown default:
                break
            }
        }
    }

    // MARK: - Controls Overlay

    private var controlsOverlay: some View {
        VStack {
            // Header
            header

            Spacer()

            // Bottom controls with extra vertical padding
            bottomControls
                .padding(.vertical, 40)
        }
        .padding(60)
    }

    private var header: some View {
        HStack {
            // Logo
            HStack(spacing: 12) {
                TVSpiralLogo(size: 44)
                    .rotationEffect(.degrees(viewModel.time * 18))
                    .accessibilityHidden(true)

                Text("UZUMAKI")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .accessibilityAddTraits(.isHeader)
            }

            Spacer()

            // Current info
            VStack(alignment: .trailing, spacing: 4) {
                Text(viewModel.spiralType.displayName)
                    .font(.headline)
                Text(viewModel.colorPreset.displayName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("\(viewModel.fps) FPS")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.white.opacity(0.5))
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Current spiral: \(viewModel.spiralType.displayName), \(viewModel.colorPreset.displayName) colors")
        }
        .opacity(0.9)
    }

    private var bottomControls: some View {
        HStack(spacing: 40) {
            // Presets button
            TVCardButton(
                title: "Presets",
                systemImage: "sparkles",
                subtitle: "Browse"
            ) {
                navigationPath.append(TVDestination.presets)
            }
            .focused($focusedControl, equals: .presets)
            .accessibilityLabel("Presets")
            .accessibilityHint("Browse preset spiral configurations")

            // Play/Pause button
            TVCardButton(
                title: viewModel.isPaused ? "Play" : "Pause",
                systemImage: viewModel.isPaused ? "play.fill" : "pause.fill",
                subtitle: viewModel.isPaused ? "Resume" : "Stop",
                isHighlighted: true
            ) {
                viewModel.togglePause()
            }
            .focused($focusedControl, equals: .playPause)
            .accessibilityLabel(viewModel.isPaused ? "Play" : "Pause")
            .accessibilityHint(viewModel.isPaused ? "Resume animation" : "Pause animation")

            // Settings button
            TVCardButton(
                title: "Settings",
                systemImage: "gearshape.fill",
                subtitle: "Configure"
            ) {
                navigationPath.append(TVDestination.settings)
            }
            .focused($focusedControl, equals: .settings)
            .accessibilityLabel("Settings")
            .accessibilityHint("Configure spiral parameters")
        }
    }

    // MARK: - Timer Management

    private func showControlsTemporarily() {
        withAnimation(.easeOut(duration: 0.25)) {
            showControls = true
        }
        resetControlsTimer()
    }

    private func resetControlsTimer() {
        controlsTimer?.cancel()
        controlsTimer = Task {
            try? await Task.sleep(for: .seconds(8))
            if !Task.isCancelled {
                await MainActor.run {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showControls = false
                    }
                }
            }
        }
    }
}

// MARK: - Navigation Destinations

enum TVDestination: Hashable {
    case settings
    case presets
}

// MARK: - Focus Control Enum

enum TVControl: Hashable {
    case presets
    case playPause
    case settings
    case spiralType
    case colorPreset
    case lineStyle
    case zoom
    case spinRate
    case reset
    case done
    case highQuality
    case dimMode
    case autoCycle
}

// MARK: - TV Card Button Component (Native tvOS Style)

/// A card-style button optimized for tvOS with proper focus effects
struct TVCardButton: View {
    let title: String
    let systemImage: String
    var subtitle: String? = nil
    var isHighlighted: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 36, weight: .medium))
                    .foregroundStyle(isHighlighted ? .white : .white.opacity(0.9))

                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)

                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            .frame(width: 240, height: 180)
            .background {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(isHighlighted
                        ? LinearGradient(
                            colors: [.blue.opacity(0.6), .purple.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                          )
                        : LinearGradient(
                            colors: [.white.opacity(0.15), .white.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                          )
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(.white.opacity(0.2), lineWidth: 1)
            }
        }
        .buttonStyle(TVCardButtonStyle())
    }
}

/// Custom button style for tvOS that provides proper focus scaling and hover effects
struct TVCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        TVCardButtonContent(configuration: configuration)
    }
}

/// Content wrapper that observes focus state
private struct TVCardButtonContent: View {
    let configuration: ButtonStyleConfiguration
    @Environment(\.isFocused) private var isFocused

    var body: some View {
        configuration.label
            .scaleEffect(isFocused ? 1.08 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .brightness(isFocused ? 0.1 : 0.0)
            .shadow(
                color: isFocused ? .white.opacity(0.3) : .clear,
                radius: isFocused ? 20 : 0
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFocused)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - TV Spiral Canvas View (Optimized)

struct TVSpiralCanvasView: View {
    @Bindable var viewModel: TVSpiralViewModel

    var body: some View {
        TimelineView(.animation(paused: viewModel.isPaused)) { timeline in
            Canvas(rendersAsynchronously: true) { context, size in
                let points = viewModel.spiralPoints
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let colors = viewModel.colors

                guard points.count > 1 else { return }

                // Draw based on line style using shared renderer
                switch viewModel.lineStyle {
                case .points:
                    SpiralRenderer.drawPoints(
                        context: context,
                        points: points,
                        center: center,
                        colors: colors,
                        zoom: viewModel.zoom
                    )
                case .triangles:
                    SpiralRenderer.drawTriangles(
                        context: context,
                        points: points,
                        center: center,
                        colors: colors
                    )
                case .glow:
                    SpiralRenderer.drawGlow(
                        context: context,
                        points: points,
                        center: center,
                        glowColor: viewModel.glowColor,
                        performanceMode: !viewModel.highQualityMode,
                        glowOnly: true
                    )
                default:
                    // Draw glow first (in high quality mode)
                    if viewModel.highQualityMode {
                        SpiralRenderer.drawGlow(
                            context: context,
                            points: points,
                            center: center,
                            glowColor: viewModel.glowColor,
                            performanceMode: false,
                            glowOnly: false
                        )
                    }
                    SpiralRenderer.drawLine(
                        context: context,
                        points: points,
                        center: center,
                        colors: colors,
                        lineStyle: viewModel.lineStyle
                    )
                }
            }
            .onChange(of: timeline.date) { oldValue, newValue in
                let delta = newValue.timeIntervalSince(oldValue)
                viewModel.incrementTime(delta: delta)
                viewModel.updateFPS()
            }
        }
        .background(viewModel.backgroundColor)
        .accessibilityLabel("Animated spiral visualization")
        .accessibilityAddTraits(.updatesFrequently)
    }
}

// MARK: - TV Settings View

struct TVSettingsView: View {
    @Bindable var viewModel: TVSpiralViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedSetting: TVControl?

    var body: some View {
        ZStack {
            // Background with blur effect
            viewModel.backgroundColor
                .ignoresSafeArea()

            // Mini spiral preview in background
            TVSpiralCanvasView(viewModel: viewModel)
                .opacity(0.3)
                .ignoresSafeArea()

            // Content
            ScrollView {
                VStack(spacing: 40) {
                    // Header
                    Text("Settings")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .accessibilityAddTraits(.isHeader)

                    // Spiral Settings Row
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Spiral")
                            .font(.title2)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 40) {
                            // Spiral Type
                            TVSettingCard(
                                title: "Spiral Type",
                                value: viewModel.spiralType.displayName,
                                systemImage: "hurricane"
                            ) {
                                viewModel.nextSpiralType()
                            }
                            .focused($focusedSetting, equals: .spiralType)
                            .accessibilityLabel("Spiral type: \(viewModel.spiralType.displayName)")
                            .accessibilityHint("Press to cycle through spiral types")

                            // Color Preset
                            TVSettingCard(
                                title: "Colors",
                                value: viewModel.colorPreset.displayName,
                                systemImage: "paintpalette.fill"
                            ) {
                                viewModel.nextColorPreset()
                            }
                            .focused($focusedSetting, equals: .colorPreset)
                            .accessibilityLabel("Color preset: \(viewModel.colorPreset.displayName)")
                            .accessibilityHint("Press to cycle through color presets")

                            // Line Style
                            TVSettingCard(
                                title: "Style",
                                value: viewModel.lineStyle.displayName,
                                systemImage: "line.diagonal"
                            ) {
                                viewModel.nextLineStyle()
                            }
                            .focused($focusedSetting, equals: .lineStyle)
                            .accessibilityLabel("Line style: \(viewModel.lineStyle.displayName)")
                            .accessibilityHint("Press to cycle through line styles")
                        }
                    }

                    // Mode Settings Row
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Modes")
                            .font(.title2)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 40) {
                            // High Quality Mode
                            TVToggleCard(
                                title: "High Quality",
                                subtitle: "More detail",
                                systemImage: "sparkles",
                                isEnabled: viewModel.highQualityMode,
                                accentColor: .green
                            ) {
                                viewModel.highQualityMode.toggle()
                            }
                            .focused($focusedSetting, equals: .highQuality)
                            .accessibilityLabel("High quality mode: \(viewModel.highQualityMode ? "On" : "Off")")
                            .accessibilityHint("Toggle high quality mode for more detail")

                            // Dim Mode
                            TVToggleCard(
                                title: "Dim Mode",
                                subtitle: "Auto-dim after 5 min",
                                systemImage: "moon.fill",
                                isEnabled: viewModel.dimModeEnabled,
                                accentColor: .purple
                            ) {
                                viewModel.dimModeEnabled.toggle()
                            }
                            .focused($focusedSetting, equals: .dimMode)
                            .accessibilityLabel("Dim mode: \(viewModel.dimModeEnabled ? "On" : "Off")")
                            .accessibilityHint("Toggle automatic dimming after extended viewing")

                            // Auto-Cycle
                            TVToggleCard(
                                title: "Auto-Cycle",
                                subtitle: "Change every 30s",
                                systemImage: "arrow.triangle.2.circlepath",
                                isEnabled: viewModel.autoCycleEnabled,
                                accentColor: .cyan
                            ) {
                                viewModel.autoCycleEnabled.toggle()
                            }
                            .focused($focusedSetting, equals: .autoCycle)
                            .accessibilityLabel("Auto-cycle: \(viewModel.autoCycleEnabled ? "On" : "Off")")
                            .accessibilityHint("Toggle automatic preset cycling")
                        }
                    }
                }
                .padding(.horizontal, 80)
                .padding(.top, 0)
                .padding(.bottom, 40)
            }
            .safeAreaInset(edge: .bottom) {
                // Bottom buttons pinned outside ScrollView
                HStack(spacing: 40) {
                    // Reset button
                    Button {
                        viewModel.reset()
                        dismiss()
                    } label: {
                        Label("Reset to Defaults", systemImage: "arrow.counterclockwise")
                            .font(.headline)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .focused($focusedSetting, equals: .reset)
                    .accessibilityLabel("Reset to defaults")
                    .accessibilityHint("Resets all settings to default values")

                    // Done button
                    Button {
                        dismiss()
                    } label: {
                        Label("Done", systemImage: "checkmark")
                            .font(.headline)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .focused($focusedSetting, equals: .done)
                    .accessibilityLabel("Done")
                    .accessibilityHint("Return to spiral view")
                }
                .padding(.bottom, 30)
            }
        }
        .onAppear {
            focusedSetting = .spiralType
        }
    }
}

/// Toggle card component for on/off settings
struct TVToggleCard: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let isEnabled: Bool
    let accentColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 20) {
                Image(systemName: systemImage)
                    .font(.system(size: 32))
                    .foregroundStyle(isEnabled ? accentColor : .white.opacity(0.4))

                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(isEnabled ? "On" : "Off")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(isEnabled ? accentColor : .white.opacity(0.6))

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.4))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(width: 300, height: 260)
            .background {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(isEnabled
                        ? AnyShapeStyle(accentColor.opacity(0.15))
                        : AnyShapeStyle(Color.black.opacity(0.3))
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(isEnabled ? accentColor.opacity(0.5) : .white.opacity(0.15), lineWidth: 1)
            }
        }
        .buttonStyle(TVCardButtonStyle())
    }
}

/// Card component for settings
struct TVSettingCard: View {
    let title: String
    let value: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                Image(systemName: systemImage)
                    .font(.system(size: 32))
                    .foregroundStyle(.white.opacity(0.7))

                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 300, height: 220)
            .background {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.ultraThinMaterial)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(.white.opacity(0.15), lineWidth: 1)
            }
        }
        .buttonStyle(TVCardButtonStyle())
    }
}

// MARK: - TV Presets View

struct TVPresetsView: View {
    @Bindable var viewModel: TVSpiralViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedPreset: String?

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        ZStack {
            // Background
            viewModel.backgroundColor
                .ignoresSafeArea()

            // Mini spiral preview in background
            TVSpiralCanvasView(viewModel: viewModel)
                .opacity(0.2)
                .ignoresSafeArea()

            // Content
            VStack(spacing: 40) {
                // Header
                Text("Presets")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .accessibilityAddTraits(.isHeader)

                // Grid of presets
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 30) {
                        ForEach(SpiralPreset.allPresets) { preset in
                            TVPresetCard(preset: preset) {
                                viewModel.loadPreset(preset)
                                dismiss()
                            }
                            .focused($focusedPreset, equals: preset.id)
                            .accessibilityLabel("\(preset.name) preset")
                            .accessibilityHint("\(preset.type.displayName) spiral with \(preset.colorPreset.displayName) colors")
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(60)
        }
        .onAppear {
            // Focus first preset
            focusedPreset = SpiralPreset.allPresets.first?.id
        }
    }
}

/// Card component for presets
struct TVPresetCard: View {
    let preset: SpiralPreset
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                // Gradient preview circle (colors only, no icon)
                Circle()
                    .fill(
                        LinearGradient(
                            colors: preset.colorPreset.colors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 70, height: 70)

                Text(preset.name)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
                    .multilineTextAlignment(.center)

                Text(preset.type.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(width: 220, height: 190)
            .background {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.ultraThinMaterial)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(.white.opacity(0.1), lineWidth: 1)
            }
        }
        .buttonStyle(TVCardButtonStyle())
    }
}

// MARK: - TV Spiral Logo

/// Custom spiral logo matching the web app favicon
struct TVSpiralLogo: View {
    let size: CGFloat

    var body: some View {
        Canvas { context, canvasSize in
            let scale = min(canvasSize.width, canvasSize.height) / 24

            var path = Path()
            path.move(to: CGPoint(x: 12 * scale, y: 12 * scale))

            // First curve
            path.addCurve(
                to: CGPoint(x: 6 * scale, y: 14 * scale),
                control1: CGPoint(x: 10 * scale, y: 9.33 * scale),
                control2: CGPoint(x: 6 * scale, y: 9.33 * scale)
            )

            // Second curve
            path.addCurve(
                to: CGPoint(x: 12 * scale, y: 20 * scale),
                control1: CGPoint(x: 6 * scale, y: 17.5 * scale),
                control2: CGPoint(x: 8.5 * scale, y: 20 * scale)
            )

            // Third curve
            path.addCurve(
                to: CGPoint(x: 20 * scale, y: 12 * scale),
                control1: CGPoint(x: 17 * scale, y: 20 * scale),
                control2: CGPoint(x: 20 * scale, y: 16 * scale)
            )

            // Fourth curve
            path.addCurve(
                to: CGPoint(x: 12 * scale, y: 2 * scale),
                control1: CGPoint(x: 20 * scale, y: 6 * scale),
                control2: CGPoint(x: 16 * scale, y: 2 * scale)
            )

            // Fifth curve
            path.addCurve(
                to: CGPoint(x: 0 * scale, y: 12 * scale),
                control1: CGPoint(x: 4 * scale, y: 2 * scale),
                control2: CGPoint(x: 0 * scale, y: 6 * scale)
            )

            // Draw with gradient
            let gradient = Gradient(colors: [
                Color(red: 0.282, green: 0.859, blue: 0.984),  // #48DBFB
                Color(red: 1.0, green: 0.420, blue: 0.420)     // #FF6B6B
            ])

            context.stroke(
                path,
                with: .linearGradient(
                    gradient,
                    startPoint: .zero,
                    endPoint: CGPoint(x: canvasSize.width, y: canvasSize.height)
                ),
                style: StrokeStyle(lineWidth: 2.5 * scale, lineCap: .round, lineJoin: .round)
            )
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Touch Surface Gesture View

/// Handles Siri Remote directional input for preset cycling and parameter adjustment
struct TVTouchSurfaceGestureView: View {
    let onSwipeLeft: () -> Void
    let onSwipeRight: () -> Void
    let onSwipeUp: () -> Void
    let onSwipeDown: () -> Void
    let onTouchPositionChanged: (CGPoint) -> Void

    @State private var currentPosition: CGPoint = CGPoint(x: 0.5, y: 0.5)

    // Step size for position adjustment
    private let positionStep: CGFloat = 0.1

    var body: some View {
        Color.clear
            .contentShape(Rectangle())
            .focusable()
            .onMoveCommand { direction in
                switch direction {
                case .left:
                    onSwipeLeft()
                case .right:
                    onSwipeRight()
                case .up:
                    onSwipeUp()
                case .down:
                    onSwipeDown()
                @unknown default:
                    break
                }
            }
            .onLongPressGesture(minimumDuration: 0.5) {
                // Long press enables position adjustment mode
                // Reset to center position
                currentPosition = CGPoint(x: 0.5, y: 0.5)
                onTouchPositionChanged(currentPosition)
            }
    }
}

#Preview {
    TVContentView()
}
#endif
