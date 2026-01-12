import SwiftUI

// MARK: - iOS 26 Liquid Glass Compatibility Layer

/// Provides backward-compatible glass effects for iOS 26 Liquid Glass design system.
/// On iOS 26+, uses native Liquid Glass. On earlier versions, falls back to materials.
extension View {
    
    /// Applies an adaptive glass effect that uses Liquid Glass on iOS 26+ or falls back to materials
    @ViewBuilder
    func adaptiveGlassEffect<S: Shape>(
        in shape: S,
        interactive: Bool = false
    ) -> some View {
        if #available(iOS 26.0, macOS 26.0, watchOS 26.0, tvOS 26.0, *) {
            let glass = interactive ? Glass.regular.interactive() : .regular
            self.glassEffect(glass, in: shape)
        } else {
            // Fallback for iOS 18 and earlier
            self
                .background(shape.fill(.ultraThinMaterial))
                .clipShape(shape)
        }
    }
    
    /// Applies a capsule-shaped glass effect
    @ViewBuilder
    func adaptiveGlassCapsule(interactive: Bool = false) -> some View {
        adaptiveGlassEffect(in: Capsule(), interactive: interactive)
    }
    
    /// Applies a rounded rectangle glass effect
    @ViewBuilder
    func adaptiveGlassRoundedRect(cornerRadius: CGFloat = 16, interactive: Bool = false) -> some View {
        adaptiveGlassEffect(in: RoundedRectangle(cornerRadius: cornerRadius), interactive: interactive)
    }
    
    /// Applies a tinted glass effect (iOS 26+ only, falls back to tinted material)
    @ViewBuilder
    func adaptiveTintedGlass<S: Shape>(
        _ tintColor: Color,
        in shape: S,
        interactive: Bool = false
    ) -> some View {
        if #available(iOS 26.0, macOS 26.0, watchOS 26.0, tvOS 26.0, *) {
            let baseGlass = interactive ? Glass.regular.interactive() : .regular
            self.glassEffect(baseGlass.tint(tintColor), in: shape)
        } else {
            self
                .background(
                    shape
                        .fill(.ultraThinMaterial)
                        .overlay(shape.fill(tintColor.opacity(0.15)))
                )
                .clipShape(shape)
        }
    }
}

// MARK: - Glass Button Style Compatibility

/// A button style that uses Liquid Glass on iOS 26+ or a custom glass-like appearance on earlier versions
struct AdaptiveGlassButtonStyle: ButtonStyle {
    var isProminent: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        if #available(iOS 26.0, macOS 26.0, watchOS 26.0, tvOS 26.0, *) {
            configuration.label
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .glassEffect(.regular.interactive(), in: Capsule())
                .opacity(configuration.isPressed ? 0.8 : 1.0)
        } else {
            configuration.label
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Capsule()
                                .stroke(.white.opacity(0.2), lineWidth: 1)
                        )
                )
                .opacity(configuration.isPressed ? 0.7 : 1.0)
        }
    }
}

extension ButtonStyle where Self == AdaptiveGlassButtonStyle {
    static var adaptiveGlass: AdaptiveGlassButtonStyle { AdaptiveGlassButtonStyle() }
    static var adaptiveGlassProminent: AdaptiveGlassButtonStyle { AdaptiveGlassButtonStyle(isProminent: true) }
}

// MARK: - Glass Effect Container Compatibility

/// A container that provides consistent glass rendering for multiple glass elements
struct AdaptiveGlassContainer<Content: View>: View {
    let spacing: CGFloat
    @ViewBuilder let content: () -> Content
    
    init(spacing: CGFloat = 16, @ViewBuilder content: @escaping () -> Content) {
        self.spacing = spacing
        self.content = content
    }
    
    var body: some View {
        if #available(iOS 26.0, macOS 26.0, watchOS 26.0, tvOS 26.0, *) {
            GlassEffectContainer(spacing: spacing) {
                content()
            }
        } else {
            content()
        }
    }
}

// MARK: - Symbol Effect Compatibility

extension View {
    /// Adds a symbol replace transition on iOS 26+, or a simple opacity transition on earlier versions
    @ViewBuilder
    func adaptiveSymbolTransition() -> some View {
        if #available(iOS 26.0, macOS 26.0, watchOS 26.0, tvOS 26.0, *) {
            self.contentTransition(.symbolEffect(.replace))
        } else if #available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *) {
            self.contentTransition(.symbolEffect(.replace))
        } else {
            self.animation(.easeInOut(duration: 0.2), value: UUID())
        }
    }
}

