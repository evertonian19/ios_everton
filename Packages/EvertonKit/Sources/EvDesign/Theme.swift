import SwiftUI

public extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: opacity)
    }
}

public enum Theme {
    public static let background = Color(hex: 0x0A1020)
    public static let surface = Color(hex: 0x121B33)
    public static let surfaceHigh = Color(hex: 0x1B2747)
    public static let line = Color(hex: 0x2A3860)
    public static let blue = Color(hex: 0x2F6BFF)
    public static let deepBlue = Color(hex: 0x003399)
    public static let gold = Color(hex: 0xF5C451)
    public static let win = Color(hex: 0x2ECC71)
    public static let draw = Color(hex: 0x9AA4B8)
    public static let loss = Color(hex: 0xE5484D)
    public static let textPrimary = Color.white
    public static let textSecondary = Color(hex: 0x8E9AB5)

    public static let heroGradient = LinearGradient(
        colors: [Color(hex: 0x14307A), Color(hex: 0x0B1B4D), Color(hex: 0x0A1020)],
        startPoint: .topLeading, endPoint: .bottomTrailing)

    /// 평점 색상 등급 (FM 의 평점 색과 비슷하게).
    public static func ratingColor(_ rating: Double?) -> Color {
        guard let rating else { return draw }
        switch rating {
        case ..<6.0: return loss
        case ..<6.7: return Color(hex: 0xF08A24)
        case ..<7.3: return Color(hex: 0xC9D63A)
        case ..<8.0: return win
        case ..<9.0: return Color(hex: 0x27D3E6)
        default: return gold
        }
    }
}
