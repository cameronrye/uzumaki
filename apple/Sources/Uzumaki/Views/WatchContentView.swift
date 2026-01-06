#if os(watchOS)
import SwiftUI
import UzumakiCore

/// Full-screen content view for watchOS
/// - Digital Crown: zoom control
/// - Swipe left/right: change preset
/// - Long press: show settings
/// - Tap: play/pause
/// - Double-tap: reset zoom
public struct WatchContentView: View {
    @State private var viewModel = WatchSpiralViewModel()
    @State private var crownValue: Double = 1.0
    @State private var showingSettings = false
    @State private var showOverlay = false
    @State private var overlayText = ""
    @State private var overlayHideTask: Task<Void, Never>?
    @State private var showOnboarding = false
    @AppStorage("watchHasSeenOnboarding") private var hasSeenOnboarding = false

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
                    showOverlayBriefly("Zoom: \(String(format: "%.1f", newValue))x")
                }

            // Pause indicator
            if viewModel.isPaused {
                Image(systemName: "pause.fill")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
                    .allowsHitTesting(false)
            }

            // Overlay text (preset name, zoom level, etc.)
            if showOverlay {
                VStack {
                    Spacer()
                    Text(overlayText)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                }
                .padding(.bottom, 8)
                .transition(.opacity)
                .allowsHitTesting(false)
            }

            // Onboarding overlay
            if showOnboarding {
                onboardingOverlay
            }
        }
        .ignoresSafeArea()
        .gesture(swipeGesture)
        .gesture(longPressGesture)
        .onTapGesture(count: 2) {
            // Double-tap to reset zoom
            viewModel.resetZoom()
            crownValue = 1.0
            showOverlayBriefly("Zoom Reset")
        }
        .onTapGesture(count: 1) {
            viewModel.togglePause()
        }
        .sheet(isPresented: $showingSettings) {
            WatchSettingsView(viewModel: viewModel)
        }
        .onAppear {
            crownValue = viewModel.zoom
            if !hasSeenOnboarding {
                showOnboarding = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        showOnboarding = false
                    }
                    hasSeenOnboarding = true
                }
            }
        }
    }

    // MARK: - Onboarding Overlay

    private var onboardingOverlay: some View {
        VStack(spacing: 8) {
            Spacer()
            VStack(alignment: .leading, spacing: 6) {
                Label("Tap to pause", systemImage: "hand.tap")
                Label("Swipe for presets", systemImage: "arrow.left.arrow.right")
                Label("Crown to zoom", systemImage: "digitalcrown.horizontal.arrow.clockwise")
                Label("Hold for settings", systemImage: "gearshape")
            }
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(.white.opacity(0.9))
            .padding(12)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            Spacer().frame(height: 20)
        }
        .transition(.opacity)
    }

    // MARK: - Gestures

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 30)
            .onEnded { value in
                let horizontalAmount = value.translation.width

                if horizontalAmount < -30 {
                    // Swipe left - next preset
                    viewModel.nextPreset()
                    showOverlayBriefly(viewModel.currentPresetName)
                } else if horizontalAmount > 30 {
                    // Swipe right - previous preset
                    viewModel.previousPreset()
                    showOverlayBriefly(viewModel.currentPresetName)
                }
            }
    }

    private var longPressGesture: some Gesture {
        LongPressGesture(minimumDuration: 0.5)
            .onEnded { _ in
                showingSettings = true
            }
    }

    private func showOverlayBriefly(_ text: String) {
        // Cancel any existing hide task
        overlayHideTask?.cancel()

        overlayText = text
        withAnimation(.easeIn(duration: 0.2)) {
            showOverlay = true
        }

        overlayHideTask = Task {
            try? await Task.sleep(for: .seconds(1.5))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.3)) {
                    showOverlay = false
                }
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

            // Line Style section
            Section("Style") {
                ForEach(LineStyle.allCases) { style in
                    Button(action: {
                        viewModel.lineStyle = style
                        dismiss()
                    }) {
                        HStack {
                            Text(style.displayName)
                            Spacer()
                            if viewModel.lineStyle == style {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
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

