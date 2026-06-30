import SwiftUI

// MARK: - App Theme

enum AppTheme {
    // Backgrounds
    static let cream        = Color(hex: "#FDF6F0")!
    static let blushLight   = Color(hex: "#FEF0F3")!
    static let blushMid     = Color(hex: "#F5DDE4")!
    static let blushBorder  = Color(hex: "#F2C4CE")!

    // Accents
    static let blushPink    = Color(hex: "#E8A0B0")!
    static let deepRose     = Color(hex: "#4A2030")!
    static let mutedRose    = Color(hex: "#8A5060")!
    static let softRose     = Color(hex: "#B87A90")!

    // Categories
    static let sage         = Color(hex: "#7DAF8C")!
    static let lavender     = Color(hex: "#B8A0C8")!
    static let blushCat     = Color(hex: "#E8A0B0")!
    static let goldCat      = Color(hex: "#C8A878")!

    static let categoryPresets: [String] = [
        "#E8A0B0",
        "#7DAF8C",
        "#B8A0C8",
        "#C8A878",
        "#A0B8C8",
        "#C8B0A0"
    ]
    
    // Text
    static let textPrimary   = Color(hex: "#2D1520")!
    static let textSecondary = Color(hex: "#8A5060")!
    static let textTertiary  = Color(hex: "#B87A90")!
    
    // Shadows
    static func cardShadow(radius: CGFloat = 8, opacity: Double = 0.08) -> some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.clear)
            .shadow(color: deepRose.opacity(opacity), radius: radius, x: 0, y: 4)
    }
}

// MARK: - Font Extensions

extension Font {
    static func playfair(_ size: CGFloat) -> Font {
        .custom("PlayfairDisplay-Regular", size: size)
    }
    
    static func playfairBold(_ size: CGFloat) -> Font {
        .custom("PlayfairDisplay-SemiBold", size: size)
    }
    
    static func playfairItalic(_ size: CGFloat) -> Font {
        .custom("PlayfairDisplay-Italic", size: size)
    }
}

// MARK: - View Modifiers

struct ThemedCardModifier: ViewModifier {
    var padding: CGFloat = 16
    var cornerRadius: CGFloat = 16
    var backgroundColor: Color = AppTheme.blushLight
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: AppTheme.deepRose.opacity(0.07), radius: 8, x: 0, y: 4)
    }
}

extension View {
    func themedCard(
        padding: CGFloat = 16,
        cornerRadius: CGFloat = 16,
        backgroundColor: Color = AppTheme.blushLight
    ) -> some View {
        modifier(ThemedCardModifier(
            padding: padding,
            cornerRadius: cornerRadius,
            backgroundColor: backgroundColor
        ))
    }
    
    func cardShadow() -> some View {
        self.shadow(color: AppTheme.deepRose.opacity(0.07), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    var backgroundColor: Color = AppTheme.deepRose
    var foregroundColor: Color = .white
    var cornerRadius: CGFloat = 14
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(foregroundColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    var cornerRadius: CGFloat = 14
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(AppTheme.deepRose)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(AppTheme.blushMid)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct GhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .medium))
            .foregroundColor(AppTheme.mutedRose)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(AppTheme.blushBorder, lineWidth: 1.5)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.6)))
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}
