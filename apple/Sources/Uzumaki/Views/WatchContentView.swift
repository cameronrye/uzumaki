#if os(watchOS)
import SwiftUI
import UzumakiCore

/// Full-screen content view for watchOS
/// - Digital Crown: zoom control
/// - Swipe left/right: change preset
/// - Long press: show settings
/// - Tap: play/pause
public struct WatchContentView: View {
    @State private var viewModel = WatchSpiralViewModel()
    @State private var crownValue: Double = 1.0
    @State private var showingSettings = false
    @State private var showPresetName = false

    public init() {}

    public var body: some View {
        ZStack {
            // Full-screen spiral canvas
            WatchSpiralCanvasView(viewModel: viewModel)
                .focusable()
                .digitalCrownRotation(
                    $crownValue,
                    from: 0.5,
                    through: 5.0,
                    by: 0.1,
                    sensitivity: .medium,
                    isContinuous: false,
                    isHapticFeedbackEnabled: true
                )
                .onChange(of: crownValue) { _, newValue in
                    viewModel.zoom = newValue
                }

            // Preset name overlay (shown briefly after swipe)
            if showPresetName {
                VStack {
                    Text(viewModel.currentPresetName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                    Spacer()
                }
                .padding(.top, 8)
                .transition(.opacity)
            }
        }
        .ignoresSafeArea()
        .gesture(swipeGesture)
        .gesture(longPressGesture)
        .onTapGesture {
            viewModel.togglePause()
        }
        .sheet(isPresented: $showingSettings) {
            WatchSettingsView(viewModel: viewModel)
        }
        .onAppear {
            crownValue = viewModel.zoom
        }
    }

    // MARK: - Gestures

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 30)
            .onEnded { value in
                let horizontalAmount = value.translation.width

                if horizontalAmount < -30 {
                    // Swipe left - next preset
                    viewModel.nextPreset()
                    showPresetNameBriefly()
                } else if horizontalAmount > 30 {
                    // Swipe right - previous preset
                    viewModel.previousPreset()
                    showPresetNameBriefly()
                }
            }
    }

    private var longPressGesture: some Gesture {
        LongPressGesture(minimumDuration: 0.5)
            .onEnded { _ in
                showingSettings = true
            }
    }

    private func showPresetNameBriefly() {
        withAnimation(.easeIn(duration: 0.2)) {
            showPresetName = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeOut(duration: 0.3)) {
                showPresetName = false
            }
        }
    }
}

/// Settings view for watchOS (accessed via long press)
struct WatchSettingsView: View {
    @Bindable var viewModel: WatchSpiralViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            // Play/Pause
            Button(action: {
                viewModel.togglePause()
                dismiss()
            }) {
                Label(
                    viewModel.isPaused ? "Play" : "Pause",
                    systemImage: viewModel.isPaused ? "play.fill" : "pause.fill"
                )
            }

            // Presets section
            Section("Presets") {
                ForEach(SpiralPreset.allPresets) { preset in
                    Button(action: {
                        viewModel.loadPreset(preset)
                        dismiss()
                    }) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(preset.name)
                                .font(.headline)
                            Text(preset.type.displayName)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            // Colors section
            Section("Colors") {
                ForEach(ColorPreset.allCases, id: \.self) { color in
                    Button(action: {
                        viewModel.colorPreset = color
                        dismiss()
                    }) {
                        HStack {
                            Text(color.displayName)
                            Spacer()
                            if viewModel.colorPreset == color {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Settings")
    }
}

#Preview {
    WatchContentView()
}
#endif

