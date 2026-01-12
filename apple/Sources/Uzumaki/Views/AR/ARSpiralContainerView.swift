#if os(iOS)
import SwiftUI
import UzumakiCore

/// Container view for AR spiral experience with coaching overlay and controls
@available(iOS 17.0, *)
public struct ARSpiralContainerView: View {
    
    // MARK: - Properties
    
    /// The spiral view model for parameter access
    @Bindable var viewModel: SpiralViewModel
    
    /// AR coordinator for managing the AR session
    @StateObject private var coordinator = ARCoordinator()
    
    /// Selected depth mode for 3D spiral
    @State private var depthMode: SpiralDepthMode = .helix(pitch: 30)
    
    /// Callback to exit AR mode
    var onDismiss: () -> Void
    
    // MARK: - Computed Properties
    
    /// Convert 2D params to 3D params
    private var params3D: SpiralParams3D {
        SpiralParams3D(
            base: viewModel.params,
            depthMode: depthMode,
            scale3D: 0.001 // Convert from points to meters
        )
    }
    
    // MARK: - Body
    
    public var body: some View {
        ZStack {
            // AR View
            ARSpiralView(
                coordinator: coordinator,
                params3D: params3D,
                colors: viewModel.colors
            )
            .ignoresSafeArea()
            
            // Coaching overlay
            if coordinator.coachingActive {
                coachingOverlay
            }
            
            // Controls overlay
            VStack {
                // Top bar with close button and mode picker
                topBar
                
                Spacer()
                
                // Placement hint
                if coordinator.planeDetected && !coordinator.spiralPlaced {
                    placementHint
                }
                
                // Bottom controls
                if coordinator.spiralPlaced {
                    bottomControls
                }
            }
            .padding()
            
            // Error toast
            if let error = coordinator.errorMessage {
                errorToast(message: error)
            }
        }
        .statusBar(hidden: true)
    }
    
    // MARK: - Subviews
    
    private var topBar: some View {
        HStack {
            // Close button
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            
            Spacer()
            
            // Depth mode picker
            Menu {
                Button("Flat") { depthMode = .flat }
                Button("Helix") { depthMode = .helix(pitch: 30) }
                Button("Layered") { depthMode = .layered(count: 3, spacing: 20) }
                Button("Cone") { depthMode = .cone(angle: 0.5) }
                Button("Bowl") { depthMode = .bowl(depth: 40) }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "cube.transparent")
                    Text(depthMode.displayName)
                        .font(.subheadline.weight(.medium))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
            }
        }
    }
    
    private var coachingOverlay: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 60, weight: .light))
                .foregroundStyle(.white.opacity(0.8))
            
            Text("Point your camera at a flat surface")
                .font(.headline)
                .foregroundStyle(.white)
            
            Text("Move your device slowly to help detect surfaces")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    private var placementHint: some View {
        HStack(spacing: 8) {
            Image(systemName: "hand.tap")
            Text("Tap to place spiral")
        }
        .font(.subheadline.weight(.medium))
        .foregroundStyle(.white)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .padding(.bottom, 20)
    }
    
    private var bottomControls: some View {
        HStack(spacing: 16) {
            // Reset placement button
            Button(action: { coordinator.removeSpiral() }) {
                Label("Remove", systemImage: "trash")
                    .font(.subheadline.weight(.medium))
            }
            .buttonStyle(.borderedProminent)
            .tint(.red.opacity(0.8))
            
            // Gesture hints
            HStack(spacing: 12) {
                gestureHint(icon: "arrow.triangle.2.circlepath", text: "Rotate")
                gestureHint(icon: "arrow.up.left.and.arrow.down.right", text: "Scale")
            }
            .font(.caption)
            .foregroundStyle(.white.opacity(0.7))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }

    private func gestureHint(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text(text)
        }
    }

    private func errorToast(message: String) -> some View {
        VStack {
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.white)
                .padding()
                .background(Color.red.opacity(0.9))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.top, 100)

            Spacer()
        }
        .transition(.move(edge: .top).combined(with: .opacity))
        .onAppear {
            // Auto-dismiss error after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                coordinator.errorMessage = nil
            }
        }
    }
}

// MARK: - Preview

@available(iOS 17.0, *)
#Preview {
    ARSpiralContainerView(
        viewModel: SpiralViewModel(),
        onDismiss: {}
    )
}
#endif

