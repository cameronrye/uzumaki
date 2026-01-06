#if os(watchOS)
import SwiftUI
import UzumakiCore

/// Simplified spiral canvas view optimized for watchOS
/// Uses performance mode and reduced complexity for smooth rendering on watch
/// Supports Always-On Display with dimmed rendering
public struct WatchSpiralCanvasView: View {
    @Bindable var viewModel: WatchSpiralViewModel
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced

    public init(viewModel: WatchSpiralViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        TimelineView(.animation(paused: viewModel.isPaused || isLuminanceReduced)) { timeline in
            Canvas { context, size in
                // Generate points
                let points = viewModel.spiralPoints
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let colors = isLuminanceReduced ? dimmedColors : viewModel.colors

                // Draw based on line style (simplified for watch)
                switch viewModel.lineStyle {
                case .points:
                    drawPoints(context: context, points: points, center: center, colors: colors)
                case .triangles:
                    drawTriangles(context: context, points: points, center: center, colors: colors)
                default:
                    drawLine(context: context, points: points, center: center, colors: colors)
                }
            }
            .onChange(of: timeline.date) { oldValue, newValue in
                let delta = newValue.timeIntervalSince(oldValue)
                viewModel.incrementTime(delta: delta)
            }
        }
        .background(viewModel.backgroundColor)
    }

    /// Dimmed colors for Always-On Display mode
    private var dimmedColors: [Color] {
        viewModel.colors.map { $0.opacity(0.3) }
    }
    
    // MARK: - Drawing Functions
    
    private func drawLine(context: GraphicsContext, points: SpiralPoints, center: CGPoint, colors: [Color]) {
        guard points.count > 1 else { return }
        
        var path = Path()
        path.move(to: CGPoint(
            x: center.x + CGFloat(points.x(at: 0)),
            y: center.y + CGFloat(points.y(at: 0))
        ))
        
        for i in 1..<points.count {
            path.addLine(to: CGPoint(
                x: center.x + CGFloat(points.x(at: i)),
                y: center.y + CGFloat(points.y(at: i))
            ))
        }
        
        // Create gradient
        let gradient = Gradient(colors: colors)
        let strokeStyle = StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round)
        
        context.stroke(path, with: .linearGradient(
            gradient,
            startPoint: CGPoint(x: center.x - 50, y: center.y - 50),
            endPoint: CGPoint(x: center.x + 50, y: center.y + 50)
        ), style: strokeStyle)
    }
    
    private func drawPoints(context: GraphicsContext, points: SpiralPoints, center: CGPoint, colors: [Color]) {
        let pointRadius: CGFloat = 1.5
        
        // Draw every other point for performance
        for i in stride(from: 0, to: points.count, by: 2) {
            let progress = Double(i) / Double(max(1, points.count - 1))
            let colorIndex = Int(progress * Double(colors.count - 1))
            let color = colors[min(colorIndex, colors.count - 1)]
            
            let point = CGPoint(
                x: center.x + CGFloat(points.x(at: i)),
                y: center.y + CGFloat(points.y(at: i))
            )
            
            let rect = CGRect(
                x: point.x - pointRadius,
                y: point.y - pointRadius,
                width: pointRadius * 2,
                height: pointRadius * 2
            )
            
            context.fill(Circle().path(in: rect), with: .color(color))
        }
    }
    
    private func drawTriangles(context: GraphicsContext, points: SpiralPoints, center: CGPoint, colors: [Color]) {
        guard points.count > 2 else { return }
        
        let origin = CGPoint(
            x: center.x + CGFloat(points.x(at: 0)),
            y: center.y + CGFloat(points.y(at: 0))
        )
        
        // Draw every 3rd triangle for performance
        for i in stride(from: 1, to: points.count, by: 3) {
            let progress = Double(i) / Double(points.count)
            let colorIndex = Int(progress * Double(colors.count - 1))
            let color = colors[min(colorIndex, colors.count - 1)]
            
            var path = Path()
            path.move(to: origin)
            
            if i > 1 {
                path.addLine(to: CGPoint(
                    x: center.x + CGFloat(points.x(at: i - 1)),
                    y: center.y + CGFloat(points.y(at: i - 1))
                ))
            }
            
            path.addLine(to: CGPoint(
                x: center.x + CGFloat(points.x(at: i)),
                y: center.y + CGFloat(points.y(at: i))
            ))
            path.addLine(to: origin)
            
            context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: 0.8, lineCap: .round))
        }
    }
}
#endif

