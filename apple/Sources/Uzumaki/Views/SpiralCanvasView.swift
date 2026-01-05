import SwiftUI
import UzumakiCore

/// SwiftUI Canvas view for rendering spirals
public struct SpiralCanvasView: View {
    @Bindable var viewModel: SpiralViewModel
    
    // Animation timing
    @State private var lastUpdate: Date = .now
    
    public init(viewModel: SpiralViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        TimelineView(.animation(paused: viewModel.isPaused)) { timeline in
            Canvas { context, size in
                // Update animation time
                _ = timeline.date
                
                // Generate points
                let points = viewModel.spiralPoints
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                
                // Draw based on line style
                switch viewModel.lineStyle {
                case .points:
                    drawPoints(context: context, points: points, center: center)
                case .triangles:
                    drawTriangles(context: context, points: points, center: center)
                case .glow:
                    drawGlow(context: context, points: points, center: center, glowOnly: true)
                default:
                    // Draw glow first (unless performance mode)
                    if !viewModel.performanceMode {
                        drawGlow(context: context, points: points, center: center, glowOnly: false)
                    }
                    drawLine(context: context, points: points, center: center)
                }
            }
            .onChange(of: timeline.date) { oldValue, newValue in
                let delta = newValue.timeIntervalSince(oldValue)
                viewModel.incrementTime(delta: delta)
                lastUpdate = newValue
            }
        }
        .background(viewModel.backgroundColor)
    }
    
    // MARK: - Drawing Functions
    
    private func drawLine(context: GraphicsContext, points: SpiralPoints, center: CGPoint) {
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
        let gradient = createGradient()
        
        var strokeStyle = StrokeStyle(
            lineWidth: Constants.lineWidthDefault,
            lineCap: .round,
            lineJoin: .round
        )
        
        // Apply dash pattern if needed
        let dash = viewModel.lineStyle.dashPattern
        if !dash.isEmpty {
            strokeStyle.dash = dash
        }
        
        context.stroke(path, with: .linearGradient(
            gradient,
            startPoint: CGPoint(x: center.x - 200, y: center.y - 200),
            endPoint: CGPoint(x: center.x + 200, y: center.y + 200)
        ), style: strokeStyle)
    }
    
    private func drawPoints(context: GraphicsContext, points: SpiralPoints, center: CGPoint) {
        let colors = viewModel.colors
        let pointRadius = max(Constants.pointRadiusMin, Constants.pointRadiusBase * viewModel.zoom)
        
        for i in 0..<points.count {
            let progress = Double(i) / Double(points.count)
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
    
    private func drawTriangles(context: GraphicsContext, points: SpiralPoints, center: CGPoint) {
        guard points.count > 1 else { return }
        
        let colors = viewModel.colors
        let origin = CGPoint(
            x: center.x + CGFloat(points.x(at: 0)),
            y: center.y + CGFloat(points.y(at: 0))
        )
        
        for i in 1..<points.count {
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
            
            context.stroke(path, with: .color(color), style: StrokeStyle(
                lineWidth: Constants.lineWidthTriangles,
                lineCap: .round,
                lineJoin: .round
            ))
        }
    }

    private func drawGlow(context: GraphicsContext, points: SpiralPoints, center: CGPoint, glowOnly: Bool) {
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

        let glowColor = viewModel.glowColor
        let layers = viewModel.performanceMode
            ? Constants.glowLayersPerformance
            : Constants.glowLayersNormal

        for layer in layers {
            let opacity = glowOnly ? layer.opacity * 2 : layer.opacity
            let width = glowOnly ? layer.width * 1.5 : layer.width

            context.stroke(path, with: .color(glowColor.opacity(opacity)), style: StrokeStyle(
                lineWidth: width,
                lineCap: .round,
                lineJoin: .round
            ))
        }
    }

    private func createGradient() -> Gradient {
        Gradient(colors: viewModel.colors)
    }
}

