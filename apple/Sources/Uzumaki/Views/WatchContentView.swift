#if os(watchOS)
import SwiftUI
import UzumakiCore

/// Simplified content view for watchOS
/// Uses Digital Crown for zoom and tap gestures for preset cycling
public struct WatchContentView: View {
    @State private var viewModel = WatchSpiralViewModel()
    @State private var crownValue: Double = 1.0
    @State private var showingPresetPicker = false
    
    public init() {}
    
    public var body: some View {
        ZStack {
            // Spiral canvas
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
            
            // Overlay controls
            VStack {
                Spacer()
                
                HStack(spacing: 12) {
                    // Play/Pause button
                    Button(action: { viewModel.togglePause() }) {
                        Image(systemName: viewModel.isPaused ? "play.fill" : "pause.fill")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .buttonStyle(.plain)
                    .frame(width: 36, height: 36)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    
                    // Preset picker button
                    Button(action: { showingPresetPicker = true }) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .buttonStyle(.plain)
                    .frame(width: 36, height: 36)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    
                    // Next spiral type
                    Button(action: { viewModel.nextSpiralType() }) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .buttonStyle(.plain)
                    .frame(width: 36, height: 36)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                }
                .padding(.bottom, 4)
            }
        }
        .ignoresSafeArea()
        .sheet(isPresented: $showingPresetPicker) {
            WatchPresetPickerView(viewModel: viewModel)
        }
        .onAppear {
            crownValue = viewModel.zoom
        }
    }
}

/// Preset picker for watchOS
struct WatchPresetPickerView: View {
    @Bindable var viewModel: WatchSpiralViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
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
        .navigationTitle("Presets")
    }
}

#Preview {
    WatchContentView()
}
#endif

