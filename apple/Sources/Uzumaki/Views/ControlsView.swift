import SwiftUI
import UzumakiCore

/// Control panel for spiral parameters
public struct ControlsView: View {
    @Bindable var viewModel: SpiralViewModel
    @State private var isExpanded: Bool = true
    var onExport: (() -> Void)?
    var onShare: (() -> Void)?

    public init(viewModel: SpiralViewModel, onExport: (() -> Void)? = nil, onShare: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.onExport = onExport
        self.onShare = onShare
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Action bar (always visible)
            actionBar
            
            if isExpanded {
                Divider()
                    .background(Color.white.opacity(0.1))
                
                // Type and style selectors
                configSection
                
                Divider()
                    .background(Color.white.opacity(0.1))
                
                // Sliders
                slidersSection
                
                // Toggles
                togglesSection
            }
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
    }
    
    // MARK: - Action Bar

    private var actionBar: some View {
        HStack(spacing: 12) {
            Button(action: viewModel.togglePause) {
                Image(systemName: viewModel.isPaused ? "play.fill" : "pause.fill")
                    .font(.system(size: 16, weight: .medium))
            }
            .help(viewModel.isPaused ? "Play (Space)" : "Pause (Space)")

            Button(action: viewModel.reset) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 16, weight: .medium))
            }
            .help("Reset (R)")

            Divider()
                .frame(height: 20)

            Button(action: { onExport?() }) {
                Image(systemName: "square.and.arrow.down")
                    .font(.system(size: 16, weight: .medium))
            }
            .help("Export (E)")

            Button(action: { onShare?() }) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 16, weight: .medium))
            }
            .help("Share")

            // Favorite button with brand gradient
            Button(action: { viewModel.toggleFavorite() }) {
                Image(systemName: viewModel.isFavorited ? "heart.fill" : "heart")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(viewModel.isFavorited ? AnyShapeStyle(BrandColors.gradient) : AnyShapeStyle(.white))
            }
            .help(viewModel.isFavorited ? "Remove from favorites" : "Add to favorites")

            Spacer()

            Button(action: { isExpanded.toggle() }) {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                    .font(.system(size: 14, weight: .medium))
            }
            .help(isExpanded ? "Collapse" : "Expand")
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    // MARK: - Config Section
    
    private var configSection: some View {
        HStack(spacing: 12) {
            // Spiral Type Picker
            Menu {
                ForEach(SpiralType.allCases) { type in
                    Button(action: { viewModel.spiralType = type }) {
                        HStack {
                            Text(type.displayName)
                            if viewModel.spiralType == type {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                configButton(label: "Spiral", value: viewModel.spiralType.displayName)
            }
            
            // Color Preset Picker
            Menu {
                ForEach(ColorPreset.allCases) { preset in
                    Button(action: { viewModel.colorPreset = preset }) {
                        HStack {
                            Text(preset.displayName)
                            if viewModel.colorPreset == preset {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                configButton(label: "Colors", value: viewModel.colorPreset.displayName)
            }
            
            // Line Style Picker
            Menu {
                ForEach(LineStyle.allCases) { style in
                    Button(action: { viewModel.lineStyle = style }) {
                        HStack {
                            Text(style.displayName)
                            if viewModel.lineStyle == style {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                configButton(label: "Style", value: viewModel.lineStyle.displayName)
            }
            
            // Presets
            Menu {
                ForEach(SpiralPreset.allPresets) { preset in
                    Button(preset.name) {
                        viewModel.loadPreset(preset)
                    }
                }
            } label: {
                Label("Presets", systemImage: "sparkles")
                    .font(.system(size: 13, weight: .medium))
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
    
    private func configButton(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
            Text(value)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Sliders Section

    private var slidersSection: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            parameterSlider(
                label: "Speed",
                value: $viewModel.spinRate,
                range: Constants.spinRateMin...Constants.spinRateMax,
                format: "%.2f"
            )

            parameterSlider(
                label: "Tightness",
                value: $viewModel.tightness,
                range: Constants.tightnessMin...Constants.tightnessMax,
                format: "%.1f"
            )

            parameterSlider(
                label: "Detail",
                value: $viewModel.stepSize,
                range: Constants.stepSizeMin...Constants.stepSizeMax,
                format: "%.2f"
            )

            // Points slider (Int)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Points")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                    Spacer()
                    Text("\(viewModel.numSteps)")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white)
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
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
                Spacer()
                Text(String(format: format, value.wrappedValue))
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white)
            }

            Slider(value: value, in: range)
                .tint(.white.opacity(0.8))
        }
    }

    // MARK: - Toggles Section

    private var togglesSection: some View {
        HStack(spacing: 12) {
            Toggle("Variable Thickness", isOn: $viewModel.lineThicknessVariation)
                .toggleStyle(ChipToggleStyle())

            Toggle("Performance Mode", isOn: $viewModel.performanceMode)
                .toggleStyle(ChipToggleStyle())

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

// MARK: - Chip Toggle Style

struct ChipToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(action: { configuration.isOn.toggle() }) {
            HStack(spacing: 6) {
                Circle()
                    .fill(configuration.isOn ? Color.white : Color.white.opacity(0.3))
                    .frame(width: 8, height: 8)

                configuration.label
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(configuration.isOn ? Color.white.opacity(0.2) : Color.white.opacity(0.1))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

