#if os(iOS) || os(macOS)
import SwiftUI
import UzumakiCore

/// Control panel for spiral parameters
public struct ControlsView: View {
    @Bindable var viewModel: SpiralViewModel
    @State private var isExpanded: Bool = false
    @Environment(\.openURL) private var openURL
    var onExport: (() -> Void)?
    var onShare: (() -> Void)?

    public init(viewModel: SpiralViewModel, onExport: (() -> Void)? = nil, onShare: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.onExport = onExport
        self.onShare = onShare
    }

    public var body: some View {
        controlsContent
            .adaptiveGlassRoundedRect(cornerRadius: 20)
    }

    @ViewBuilder
    private var controlsContent: some View {
        VStack(spacing: 0) {
            // Action bar (always visible)
            actionBar

            // Quick presets strip (always visible)
            quickPresetsStrip

            if isExpanded {
                VStack(spacing: 0) {
                    Divider()
                        .background(Color.white.opacity(0.1))

                    // Parameter sliders
                    slidersSection

                    Divider()
                        .background(Color.white.opacity(0.1))

                    // Appearance options (colors, line style, background)
                    configSection

                    Divider()
                        .background(Color.white.opacity(0.1))

                    // Attribution footer
                    madeWithLoveFooter
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: isExpanded)
        .clipped()
    }

    // MARK: - Quick Presets Strip

    private var quickPresetsStrip: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(SpiralPreset.allPresets) { preset in
                        presetChip(preset)
                            .id(preset.id)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("QuickPresetsStrip")
    }

    private func presetChip(_ preset: SpiralPreset) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                viewModel.loadPreset(preset)
            }
        }) {
            HStack(spacing: 6) {
                // Mini color preview dots
                HStack(spacing: 2) {
                    ForEach(0..<min(3, preset.colorPreset.colors.count), id: \.self) { index in
                        Circle()
                            .fill(preset.colorPreset.colors[index])
                            .frame(width: 5, height: 5)
                    }
                }

                Text(preset.name)
                    .font(.caption.weight(.medium))
                    .lineLimit(1)
            }
            .foregroundStyle(.white.opacity(0.9))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isCurrentPreset(preset) ? Color.white.opacity(0.2) : Color.white.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isCurrentPreset(preset) ? Color.white.opacity(0.4) : Color.clear, lineWidth: 1)
            )
            // Accessibility identifier on the content for XCTest to find
            .accessibilityIdentifier("Preset_\(preset.name.replacingOccurrences(of: " ", with: "_"))")
        }
        // Also set identifier on the Button itself
        .accessibilityIdentifier("Preset_\(preset.name.replacingOccurrences(of: " ", with: "_"))")
    }

    private func isCurrentPreset(_ preset: SpiralPreset) -> Bool {
        viewModel.spiralType == preset.type &&
        viewModel.colorPreset == preset.colorPreset &&
        viewModel.lineStyle == preset.lineStyle
    }
    
    // MARK: - Action Bar

    private var actionBar: some View {
        HStack(spacing: 0) {
            // Play/Pause button
            actionButton(
                icon: viewModel.isPaused ? "play.fill" : "pause.fill",
                help: viewModel.isPaused ? "Play (Space)" : "Pause (Space)",
                action: viewModel.togglePause
            )
            .symbolEffect(.bounce, value: viewModel.isPaused)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .adaptiveGlassRoundedRect(cornerRadius: 12, interactive: true)

            Spacer().frame(width: 12)

            // Spiral type indicator (fills available space)
            spiralTypeButton

            Spacer().frame(width: 12)

            // Expand/Collapse with rotation animation
            Button(action: {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            }) {
                Image(systemName: "chevron.down")
                    .font(.footnote.weight(.semibold))
                    .rotationEffect(.degrees(isExpanded ? 0 : 180))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help(isExpanded ? "Collapse" : "Expand")
            .accessibilityLabel(isExpanded ? "Collapse controls" : "Expand controls")
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private func actionButton(icon: String, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title3.weight(.medium))
                .frame(width: 44, height: 44) // Minimum 44pt touch target (Apple HIG)
                .contentShape(Rectangle())
                .adaptiveSymbolTransition()
        }
        .help(help)
        .accessibilityLabel(help)
        .accessibilityAddTraits(.isButton)
    }

    private var spiralTypeButton: some View {
        Menu {
            ForEach(SpiralType.allCases) { type in
                Button(action: { viewModel.spiralType = type }) {
                    HStack {
                        Text(type.displayName)
                        Text(type.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        if viewModel.spiralType == type {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack {
                Text(viewModel.spiralType.displayName)
                    .font(.subheadline.weight(.semibold))
                    .contentTransition(.identity)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.6))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .adaptiveGlassRoundedRect(cornerRadius: 12, interactive: true)
        }
        .transaction { transaction in
            transaction.animation = nil
        }
    }

    private var moreMenu: some View {
        Menu {
            // Share option
            Button(action: { onShare?() }) {
                Label("Share", systemImage: "square.and.arrow.up")
            }

            // Export option with keyboard hint
            Button(action: { onExport?() }) {
                Label("Export Image", systemImage: "square.and.arrow.down")
            }
            #if os(macOS)
            .keyboardShortcut("e", modifiers: [])
            #endif

            Divider()

            // Settings toggles
            Toggle(isOn: $viewModel.lineThicknessVariation) {
                Label("Variable Line Thickness", systemImage: "line.diagonal")
            }

            Toggle(isOn: $viewModel.performanceMode) {
                Label("Fast Mode", systemImage: "hare")
            }

            #if os(macOS)
            Divider()

            // Keyboard shortcuts hint section
            Section("Keyboard Shortcuts") {
                Text("Space - Play/Pause")
                Text("R - Reset")
                Text("E - Export")
            }
            #endif
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.title2.weight(.medium))
                .frame(width: 44, height: 44) // Minimum touch target
                .contentShape(Rectangle())
        }
        .help("More Options")
        .accessibilityLabel("More options menu")
    }
    
    // MARK: - Config Section

    private var configSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Color Preset Picker with swatch preview
                colorPresetPicker

                // Line Style Picker with icons
                lineStylePicker

                // Background Theme Picker
                backgroundPicker

                // More menu for secondary actions
                moreMenu
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }

    private var colorPresetPicker: some View {
        Menu {
            ForEach(ColorPreset.allCases) { preset in
                Button(action: { viewModel.colorPreset = preset }) {
                    HStack {
                        // Color swatch indicator
                        HStack(spacing: 2) {
                            ForEach(0..<min(3, preset.colors.count), id: \.self) { index in
                                Circle()
                                    .fill(preset.colors[index])
                                    .frame(width: 8, height: 8)
                            }
                        }
                        Text(preset.displayName)
                        Spacer()
                        if viewModel.colorPreset == preset {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                // Mini color swatch
                HStack(spacing: 2) {
                    ForEach(0..<min(3, viewModel.colorPreset.colors.count), id: \.self) { index in
                        Circle()
                            .fill(viewModel.colorPreset.colors[index])
                            .frame(width: 6, height: 6)
                    }
                }
                Text(viewModel.colorPreset.displayName)
                    .font(.footnote.weight(.semibold))
            }
            .foregroundStyle(.white.opacity(0.95))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .adaptiveGlassRoundedRect(cornerRadius: 8, interactive: true)
        }
    }

    private var lineStylePicker: some View {
        Menu {
            ForEach(LineStyle.allCases) { style in
                Button(action: { viewModel.lineStyle = style }) {
                    HStack {
                        Image(systemName: lineStyleIcon(for: style))
                        Text(style.displayName)
                        Spacer()
                        if viewModel.lineStyle == style {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: lineStyleIcon(for: viewModel.lineStyle))
                    .font(.caption.weight(.medium))
                Text(viewModel.lineStyle.displayName)
                    .font(.footnote.weight(.semibold))
            }
            .foregroundStyle(.white.opacity(0.95))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .adaptiveGlassRoundedRect(cornerRadius: 8, interactive: true)
        }
    }

    private func lineStyleIcon(for style: LineStyle) -> String {
        switch style {
        case .solid: return "line.diagonal"
        case .dashed: return "line.horizontal.3"
        case .dotted: return "ellipsis"
        case .points: return "circle.grid.2x2"
        case .triangles: return "triangle"
        case .glow: return "sparkle"
        }
    }

    private var backgroundPicker: some View {
        Menu {
            ForEach(BackgroundTheme.allCases) { theme in
                Button(action: { viewModel.backgroundTheme = theme }) {
                    HStack {
                        Image(systemName: backgroundThemeIcon(for: theme))
                        Text(theme.displayName)
                        Spacer()
                        if viewModel.backgroundTheme == theme {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: backgroundThemeIcon(for: viewModel.backgroundTheme))
                    .font(.caption.weight(.medium))
                Text("Background")
                    .font(.footnote.weight(.semibold))
                    .lineLimit(1)
                    .fixedSize()
            }
            .foregroundStyle(.white.opacity(0.95))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .adaptiveGlassRoundedRect(cornerRadius: 8, interactive: true)
        }
    }

    private func backgroundThemeIcon(for theme: BackgroundTheme) -> String {
        switch theme {
        case .dark: return "moon.fill"
        case .black: return "circle.fill"
        case .gradient: return "circle.lefthalf.filled"
        case .matching: return "paintpalette"
        }
    }

    // MARK: - Sliders Section

    private var slidersSection: some View {
        VStack(spacing: 12) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                parameterSlider(
                    label: "Animation Speed",
                    value: $viewModel.spinRate,
                    range: Constants.spinRateMin...Constants.spinRateMax,
                    format: "%.2f"
                )

                parameterSlider(
                    label: "Spiral Density",
                    value: $viewModel.tightness,
                    range: Constants.tightnessMin...Constants.tightnessMax,
                    format: "%.1f"
                )

                parameterSlider(
                    label: "Smoothness",
                    value: $viewModel.stepSize,
                    range: Constants.stepSizeMin...Constants.stepSizeMax,
                    format: "%.2f"
                )

                // Complexity slider (Int)
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Complexity")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.white.opacity(0.85))
                        Spacer()
                        Text("\(viewModel.numSteps)")
                            .font(.caption2.weight(.semibold).monospaced())
                            .foregroundStyle(.white.opacity(0.95))
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

            // Zoom, Pan, and FPS info (always visible, centered)
            HStack(spacing: 16) {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .font(.caption2.weight(.medium))
                    Text("\(viewModel.zoom, specifier: "%.1f")x")
                        .font(.caption2.weight(.semibold).monospaced())
                }

                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.and.down.and.arrow.left.and.right")
                        .font(.caption2.weight(.medium))
                    Text("\(Int(viewModel.panX)), \(Int(viewModel.panY))")
                        .font(.caption2.weight(.semibold).monospaced())
                }

                HStack(spacing: 6) {
                    Image(systemName: "speedometer")
                        .font(.caption2.weight(.medium))
                    Text("\(viewModel.fps) fps")
                        .font(.caption2.weight(.semibold).monospaced())
                        .contentTransition(.numericText())
                }
            }
            .frame(maxWidth: .infinity)
            .foregroundStyle(.white.opacity(0.6))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func parameterSlider(
        label: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        format: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.white.opacity(0.85))
                Spacer()
                Text(String(format: format, value.wrappedValue))
                    .font(.caption2.weight(.semibold).monospaced())
                    .foregroundStyle(.white.opacity(0.95))
            }

            Slider(value: value, in: range)
                .tint(.white.opacity(0.8))
        }
    }

    // MARK: - Made with Love Footer

    private var madeWithLoveFooter: some View {
        Button(action: {
            if let url = URL(string: "https://rye.dev") {
                openURL(url)
            }
        }) {
            HStack(spacing: 4) {
                Text("made with")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.white.opacity(0.5))

                BeatingHeart()

                Text("by Cameron Rye")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Made with love by Cameron Rye. Tap to visit website.")
    }
}

// MARK: - Beating Heart

/// Animated heart icon with a pulsing "beating" effect
struct BeatingHeart: View {
    @State private var isBeating = false

    var body: some View {
        Image(systemName: "heart.fill")
            .font(.caption2.weight(.medium))
            .foregroundStyle(BrandColors.gradient)
            .scaleEffect(isBeating ? 1.2 : 1.0)
            .animation(
                .easeInOut(duration: 0.5)
                    .repeatForever(autoreverses: true),
                value: isBeating
            )
            .onAppear {
                isBeating = true
            }
    }
}
#endif  // os(iOS) || os(macOS)
