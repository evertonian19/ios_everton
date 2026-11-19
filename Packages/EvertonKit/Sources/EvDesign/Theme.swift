import SwiftUI
import EvCore

public extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: opacity)
    }
}

/// Football Manager 풍 팔레트: 어두운 슬레이트 바탕, 패널 헤더 바, 파란 포인트.
public enum Theme {
    public static let background = Color(hex: 0x11151C)
    public static let surface = Color(hex: 0x1A212B)
    public static let surfaceHigh = Color(hex: 0x232C3A)
    public static let panelHeader = Color(hex: 0x232C3A)
    public static let line = Color(hex: 0x2C3646)
    public static let blue = Color(hex: 0x3FA9F5)
    public static let deepBlue = Color(hex: 0x17325F)
    public static let gold = Color(hex: 0xF5C451)
    public static let win = Color(hex: 0x2FA56B)
    public static let draw = Color(hex: 0x7B879D)
    public static let loss = Color(hex: 0xD5484B)
    public static let textPrimary = Color(hex: 0xE6EAF2)
    public static let textSecondary = Color(hex: 0x8793A6)

    public static let heroGradient = LinearGradient(
        colors: [Color(hex: 0x17325F), Color(hex: 0x101B33)], startPoint: .topLeading, endPoint: .bottomTrailing)

    /// 포지션 배지 색 (FM 처럼 포지션 그룹마다 고정 색).
    public static func positionColor(_ position: String) -> Color {
        switch position {
        case "GK": return Color(hex: 0xE9C547)
        case "DF": return Color(hex: 0x4C9BEA)
        case "MF": return Color(hex: 0x4CC38A)
        default: return Color(hex: 0xEF6A63)
        }
    }

    /// 0...1 로 정규화한 값을 FM 속성 숫자처럼 빨강→주황→노랑→초록→청록으로 칠한다.
    public static func attributeColor(_ value: Double) -> Color {
        switch value {
        case ..<0.2: return Color(hex: 0xD5484B)
        case ..<0.4: return Color(hex: 0xE8863A)
        case ..<0.6: return Color(hex: 0xD9C23B)
        case ..<0.8: return Color(hex: 0x5BC27A)
        default: return Color(hex: 0x2FD3C0)
        }
    }

    /// 순위표 왼쪽 막대 색.
    public static func zoneColor(_ zone: StandingRow.Zone) -> Color {
        switch zone {
        case .champions: return Color(hex: 0x3FA9F5)
        case .europa: return Color(hex: 0xF5A524)
        case .conference: return Color(hex: 0x4CC38A)
        case .relegation: return Color(hex: 0xE5484D)
        case .none: return .clear
        }
    }
}
