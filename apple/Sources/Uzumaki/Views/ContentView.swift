import SwiftUI
import UzumakiCore

/// Main content view for the Uzumaki app
public struct ContentView: View {
    @State private var viewModel = SpiralViewModel()
    
    // Gesture state
    @State private var currentZoom: Double = 1.0
    @State private var currentPan: CGSize = .zero
    
    public init() {}
    
    public var body: some View {
        ZStack {
            // Background
            viewModel.backgroundColor
                .ignoresSafeArea()
            
            // Spiral Canvas with gestures
            SpiralCanvasView(viewModel: viewModel)
                .gesture(zoomGesture)
                .gesture(panGesture)
                .ignoresSafeArea()
            
            // UI Overlay
            VStack {
                // Header
                header
                
                Spacer()
                
                // Zoom indicator
                zoomIndicator
                    .padding(.bottom, 8)
                
                // Controls
                ControlsView(viewModel: viewModel, onExport: exportSpiral, onShare: shareSpiral)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
            }
            
            // Toast
            if let message = viewModel.toastMessage {
                toastView(message: message)
            }
        }
        #if os(macOS)
        .frame(minWidth: 800, minHeight: 600)
        .onReceive(NotificationCenter.default.publisher(for: .togglePause)) { _ in
            viewModel.togglePause()
        }
        .onReceive(NotificationCenter.default.publisher(for: .reset)) { _ in
            viewModel.reset()
            currentZoom = 1.0
            currentPan = .zero
        }
        .onReceive(NotificationCenter.default.publisher(for: .export)) { _ in
            exportSpiral()
        }
        #endif
    }
    
    // MARK: - Header

    private var header: some View {
        HStack {
            // Spiral logo matching web favicon
            SpiralLogo(size: 28)
                .rotationEffect(.degrees(viewModel.time * 18)) // Slow spin like web

            Text("UZUMAKI")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .opacity(0.6)
    }

    // MARK: - Zoom Indicator
    
    private var zoomIndicator: some View {
        HStack(spacing: 16) {
            Text("Zoom: \(viewModel.zoom, specifier: "%.1f")x")
                .font(.system(size: 12, weight: .medium, design: .monospaced))
            
            if viewModel.panX != 0 || viewModel.panY != 0 {
                Text("Pan: \(Int(viewModel.panX)), \(Int(viewModel.panY))")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
            }
        }
        .foregroundStyle(.white.opacity(0.5))
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }
    
    // MARK: - Toast
    
    private func toastView(message: String) -> some View {
        VStack {
            Spacer()
            
            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.black.opacity(0.8))
                .clipShape(Capsule())
                .transition(.move(edge: .bottom).combined(with: .opacity))
            
            Spacer().frame(height: 100)
        }
        .animation(.spring(duration: 0.3), value: viewModel.toastMessage)
    }
    
    // MARK: - Gestures
    
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
                    let success = await ExportManager.saveToPhotos(data: data)
                    if success {
                        viewModel.showToast("Saved to Photos!")
                    } else {
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
                    // macOS: use export for now
                    ExportManager.savePNG(data: data)
                    viewModel.showToast("Spiral exported!")
                    #endif
                } else {
                    viewModel.showToast("Share failed")
                }
            }
        }
    }
}

// MARK: - Spiral Logo

/// Custom spiral logo matching the web app favicon
struct SpiralLogo: View {
    let size: CGFloat

    var body: some View {
        Canvas { context, canvasSize in
            // Scale to fit the canvas
            let scale = min(canvasSize.width, canvasSize.height) / 24

            // Create the spiral path matching web favicon
            var path = Path()
            path.move(to: CGPoint(x: 12 * scale, y: 12 * scale))

            // First curve: c-2-2.67-6-2.67-6 2
            path.addCurve(
                to: CGPoint(x: 6 * scale, y: 14 * scale),
                control1: CGPoint(x: 10 * scale, y: 9.33 * scale),
                control2: CGPoint(x: 6 * scale, y: 9.33 * scale)
            )

            // Second curve: 0 3.5 2.5 6 6 6
            path.addCurve(
                to: CGPoint(x: 12 * scale, y: 20 * scale),
                control1: CGPoint(x: 6 * scale, y: 17.5 * scale),
                control2: CGPoint(x: 8.5 * scale, y: 20 * scale)
            )

            // Third curve: 5 0 8-4 8-8
            path.addCurve(
                to: CGPoint(x: 20 * scale, y: 12 * scale),
                control1: CGPoint(x: 17 * scale, y: 20 * scale),
                control2: CGPoint(x: 20 * scale, y: 16 * scale)
            )

            // Fourth curve: 0-6-4-10-10-10
            path.addCurve(
                to: CGPoint(x: 10 * scale, y: 2 * scale),
                control1: CGPoint(x: 20 * scale, y: 6 * scale),
                control2: CGPoint(x: 16 * scale, y: 2 * scale)
            )

            // Fifth curve: -8 0-12 6-12 12
            path.addCurve(
                to: CGPoint(x: -2 * scale, y: 14 * scale),
                control1: CGPoint(x: 2 * scale, y: 2 * scale),
                control2: CGPoint(x: -2 * scale, y: 8 * scale)
            )

            // Create gradient matching brand colors
            let gradient = Gradient(colors: [BrandColors.primary, BrandColors.secondary])
            let rect = CGRect(origin: .zero, size: canvasSize)

            context.stroke(
                path,
                with: .linearGradient(
                    gradient,
                    startPoint: rect.origin,
                    endPoint: CGPoint(x: rect.maxX, y: rect.maxY)
                ),
                style: StrokeStyle(lineWidth: 2 * scale, lineCap: .round, lineJoin: .round)
            )
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    ContentView()
}

