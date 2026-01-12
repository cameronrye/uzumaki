#if os(iOS)
import ARKit
import RealityKit
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
            // AR View with coaching overlay
            ARSpiralViewWithCoaching(
                coordinator: coordinator,
                params3D: params3D,
                colors: viewModel.colors
            )
            .ignoresSafeArea()

            // Controls overlay
            VStack {
                // Top bar with close button and mode picker
                topBar

                Spacer()

                // Focus indicator hint
                if !coordinator.spiralPlaced {
                    focusHint
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

    private var focusHint: some View {
        VStack(spacing: 8) {
            // Crosshair indicator
            Image(systemName: coordinator.focusOnSurface ? "plus.circle.fill" : "plus.circle")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(coordinator.focusOnSurface ? .green : .white.opacity(0.5))
                .animation(.easeInOut(duration: 0.2), value: coordinator.focusOnSurface)

            // Dynamic placement hint
            if coordinator.focusOnSurface {
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
                .transition(.scale.combined(with: .opacity))
            } else if coordinator.planeDetected {
                Text("Point at a flat surface")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                    .transition(.opacity)
            }
        }
        .padding(.bottom, 40)
        .animation(.easeInOut(duration: 0.3), value: coordinator.focusOnSurface)
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
                gestureHint(icon: "hand.draw", text: "Move")
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

// MARK: - AR View with Coaching Overlay

/// UIViewRepresentable that combines ARView with ARCoachingOverlayView
@available(iOS 17.0, *)
struct ARSpiralViewWithCoaching: UIViewRepresentable {

    @ObservedObject var coordinator: ARCoordinator
    let params3D: SpiralParams3D
    let colors: [Color]

    func makeUIView(context: Context) -> ARContainerView {
        let containerView = ARContainerView()
        containerView.configure(
            coordinator: coordinator,
            tapHandler: context.coordinator
        )
        return containerView
    }

    func updateUIView(_ containerView: ARContainerView, context: Context) {
        if coordinator.spiralPlaced {
            coordinator.updateSpiral(params: params3D, colors: colors)
        }
    }

    func makeCoordinator() -> TapCoordinator {
        TapCoordinator(self)
    }

    static func dismantleUIView(_ containerView: ARContainerView, coordinator: TapCoordinator) {
        coordinator.parent.coordinator.pauseSession()
    }

    @MainActor
    class TapCoordinator: NSObject {
        var parent: ARSpiralViewWithCoaching

        init(_ parent: ARSpiralViewWithCoaching) {
            self.parent = parent
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let arView = gesture.view as? ARView else { return }
            let location = gesture.location(in: arView)

            parent.coordinator.placeSpiral(
                at: location,
                params: parent.params3D,
                colors: parent.colors
            )
        }
    }
}

/// Container view that holds both ARView and ARCoachingOverlayView
@available(iOS 17.0, *)
class ARContainerView: UIView {

    private var arView: ARView?
    private var coachingOverlay: ARCoachingOverlayView?

    func configure(
        coordinator: ARCoordinator,
        tapHandler: ARSpiralViewWithCoaching.TapCoordinator
    ) {
        // Create AR View
        let arView = ARView(frame: bounds)
        arView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(arView)
        self.arView = arView

        // Configure AR session
        coordinator.configureSession(for: arView)

        // Add tap gesture
        let tapGesture = UITapGestureRecognizer(
            target: tapHandler,
            action: #selector(ARSpiralViewWithCoaching.TapCoordinator.handleTap(_:))
        )
        arView.addGestureRecognizer(tapGesture)

        // Add coaching overlay
        let coaching = ARCoachingOverlayView()
        coaching.session = arView.session
        coaching.goal = .horizontalPlane
        coaching.activatesAutomatically = true
        coaching.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        coaching.frame = bounds
        addSubview(coaching)
        self.coachingOverlay = coaching
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        arView?.frame = bounds
        coachingOverlay?.frame = bounds
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

