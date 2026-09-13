import SwiftUI

enum DesignTokens {
    // Primary
    static let primary = Color(hex: 0x2F6B4F)
    static let primaryDark = Color(hex: 0x1F5546)
    static let primaryMid = Color(hex: 0x2A5F4E)

    // Accent — badge only (spec forbids using this anywhere else)
    static let badgeBackground = Color(hex: 0xFFC857)
    static let badgeForeground = Color(hex: 0x7A5A12)

    // Text
    static let textPrimary = Color(hex: 0x23231F)
    static let textBody = Color(hex: 0x3D3D3A)
    static let textSecondary = Color(hex: 0x8A8A82)
    static let textTertiary = Color(hex: 0x96968C)

    // Background
    static let pageBackground = Color(hex: 0xF7F9F4)
    static let cardBackground = Color.white
    static let tagBackground = Color(hex: 0xE7F0E8)
    static let searchFieldBackground = Color(hex: 0xF1F4EF)

    // Match score
    static let matchScoreText = Color(hex: 0x24513C)
    static let progressTrack = Color(hex: 0xE8EDE6)

    // Caution callout (neutral/amber — not green)
    static let cautionBackground = Color(hex: 0xFBF3E7)
    static let cautionIcon = Color(hex: 0x8A6A2F)
    static let cautionTitle = Color(hex: 0x6B5223)
    static let cautionBody = Color(hex: 0x5A4520)

    // Divider
    static let divider = Color(hex: 0xC6C6BD)

    // Error
    static let errorBorder = Color(hex: 0xC0392B)
    static let errorBackground = Color(hex: 0xFDF0EE)

    // Disabled
    static let disabledBackground = Color(hex: 0xE4E4DC)
    static let disabledText = Color(hex: 0x9A9A90)

    // Layout
    static let cardCornerRadius: CGFloat = 16
    static let buttonCornerRadius: CGFloat = 15
    static let tagCornerRadius: CGFloat = 8
    static let primaryButtonHeight: CGFloat = 54
}

extension Color {
    init(hex: Int) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

extension View {
    func cardShadow() -> some View {
        self
            .shadow(color: Color(hex: 0x23231F).opacity(0.06), radius: 2, x: 0, y: 1)
            .shadow(color: Color(hex: 0x23231F).opacity(0.05), radius: 18, x: 0, y: 6)
    }
}
