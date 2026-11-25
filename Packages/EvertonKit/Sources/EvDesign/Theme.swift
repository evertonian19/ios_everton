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

/// 에버턴 브랜드 팔레트: 로열 블루 상단 바·히어로, 밝은 바탕에 흰 카드. 파랑은 포인트로만 쓴다.
/// (대시보드의 iOS 목업 `public/css/ios.css` 의 토큰과 같은 값)
public enum Theme {
    public static let brand = Color(hex: 0x003399)
    public static let brandDeep = Color(hex: 0x001E62)
    public static let background = Color(hex: 0xF2F4F8)
    public static let surface = Color.white
    public static let surfaceHigh = Color(hex: 0xEEF2FA)
    public static let panelHeader = Color.white
    public static let line = Color(hex: 0xE3E7EF)
    public static let blue = brand
    public static let deepBlue = brandDeep
    public static let gold = Color(hex: 0xE3A51A)
    public static let win = Color(hex: 0x1E9E5A)
    public static let draw = Color(hex: 0x8A94A6)
    public static let loss = Color(hex: 0xD93A3F)
    public static let textPrimary = Color(hex: 0x0F1B33)
    public static let textSecondary = Color(hex: 0x5E6B82)
    /// 로열 블루 위의 글자색
    public static let onBrand = Color.white
    public static let onBrand2 = Color(hex: 0xC9D6F2)
    /// 카드의 옅은 그림자
    public static let shadow = Color(red: 15 / 255, green: 27 / 255, blue: 51 / 255).opacity(0.07)

    public static let heroGradient = LinearGradient(
        colors: [brand, brandDeep], startPoint: .topLeading, endPoint: .bottomTrailing)

    /// 스타디움 야간 조명 느낌의 히어로 배경 (위쪽이 밝고 아래로 어두워진다).
    public static let stadiumGradient = LinearGradient(
        colors: [Color(hex: 0x0A2E8A), brand, brandDeep, Color(hex: 0x000F36)],
        startPoint: .top, endPoint: .bottom)

    /// 포지션 배지 색 (포지션 그룹마다 고정 색).
    public static func positionColor(_ position: String) -> Color {
        switch position {
        case "GK": return Color(hex: 0xE9C547)
        case "DF": return Color(hex: 0x4C9BEA)
        case "MF": return Color(hex: 0x4CC38A)
        default: return Color(hex: 0xEF6A63)
        }
    }

    /// 0...1 로 정규화한 값을 속성 숫자처럼 빨강→주황→노랑→초록→청록으로 칠한다.
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
        case .champions: return Color(hex: 0x2F7BEA)
        case .europa: return Color(hex: 0xF5A524)
        case .conference: return Color(hex: 0x4CC38A)
        case .relegation: return Color(hex: 0xE5484D)
        case .none: return .clear
        }
    }
}
