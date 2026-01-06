import SwiftUI
import UzumakiCore
#if os(iOS)
import UIKit
#endif

/// Main content view for the Uzumaki app
public struct ContentView: View {
    @State private var viewModel = SpiralViewModel()

    // Gesture state
    @State private var currentZoom: Double = 1.0
    @State private var currentPan: CGSize = .zero
    @State private var showOnboardingHint: Bool = true

    // Permission alert state
    @State private var showPhotoPermissionAlert: Bool = false

    // Environment for reduced motion
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init() {}

    public var body: some View {
        ZStack {
            // Background
            viewModel.backgroundColor
                .ignoresSafeArea()

            // Spiral Canvas with gestures
            GeometryReader { geometry in
                SpiralCanvasView(viewModel: viewModel)
                    .gesture(doubleTapGesture)
                    .gesture(zoomGesture)
                    .gesture(panGesture)
                    .onAppear {
                        viewModel.updateViewportScale(for: geometry.size)
                    }
                    .onChange(of: geometry.size) { _, newSize in
                        viewModel.updateViewportScale(for: newSize)
                    }
            }
            .ignoresSafeArea()

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

    private var zoomGesture: some Gesture {
        MagnificationGesture()
            .onChanged { scale in
                let newZoom = currentZoom * scale
                viewModel.zoom = max(Constants.zoomMin, min(Constants.zoomMax, newZoom))
            }
            .onEnded { scale in
                currentZoom = viewModel.zoom
            }
    }

    private var panGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                viewModel.panX = currentPan.width + value.translation.width
                viewModel.panY = currentPan.height + value.translation.height
            }
            .onEnded { value in
                currentPan = CGSize(width: viewModel.panX, height: viewModel.panY)
            }
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
        #if os(iOS)
        // Haptic feedback on iOS
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        #endif
    }

    // MARK: - Export

    private func exportSpiral() {
        Task {
            if #available(macOS 14.0, iOS 17.0, *) {
                if let data = await ExportManager.exportAsPNG(viewModel: viewModel) {
                    #if os(macOS)
                    ExportManager.savePNG(data: data)
                    viewModel.showToast("Spiral exported!")
                    #else
                    // On iOS, save to Photos
                    let result = await ExportManager.saveToPhotos(data: data)
                    switch result {
                    case .success:
                        viewModel.showToast("Saved to Photos!")
                        viewModel.triggerSuccessFeedback()
                    case .permissionDenied:
                        showPhotoPermissionAlert = true
                    case .failed:
                        viewModel.showToast("Could not save to Photos")
                    }
                    #endif
                } else {
                    viewModel.showToast("Export failed")
                }
            } else {
                viewModel.showToast("Export requires iOS 17+ / macOS 14+")
            }
        }
    }

    private func shareSpiral() {
        Task {
            if #available(macOS 14.0, iOS 17.0, *) {
                if let data = await ExportManager.exportAsPNG(viewModel: viewModel) {
                    #if os(iOS)
                    ExportManager.share(data: data)
                    #else
                    // macOS: use proper share sheet
                    ExportManager.share(data: data)
                    #endif
                } else {
                    viewModel.showToast("Share failed")
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
