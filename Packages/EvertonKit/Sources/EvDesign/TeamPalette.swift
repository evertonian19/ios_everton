import SwiftUI
import EvCore

/// 구단 색: 주색 · 어두운 색 · 발광색. 히어로 그라데이션, 글로우, 피치 토큰이 모두 이 색에서 나온다.
/// ESPN 이 주는 색은 흰색·검정이 섞여 있어 믿을 수 없으므로 구단 코드로 직접 정한 표를 쓴다
/// (대시보드 목업 `ios.js` 의 `TEAM_PAL` 과 같은 값).
public struct TeamPalette: Equatable, Sendable {
    let mainHex: UInt32
    let deepHex: UInt32
    let glowHex: UInt32

    public var main: Color { Color(hex: mainHex) }
    public var deep: Color { Color(hex: deepHex) }
    public var glow: Color { Color(hex: glowHex) }
    /// 주색에 흰색을 섞은 밝은 색(그라데이션 윗부분).
    public var light: Color { Color(hex: Self.blend(mainHex, 0xFFFFFF, 0.38)) }

    /// 위에서 아래로 밝은 색 → 주색 → 어두운 색.
    public var gradient: LinearGradient {
        LinearGradient(colors: [light, main, deep], startPoint: .top, endPoint: .bottom)
    }

    public static let everton = TeamPalette(mainHex: 0x0B3FB8, deepHex: 0x031A54, glowHex: 0xF2B84B)

    private static let table: [String: TeamPalette] = [
        "EVE": everton,
        "ARS": TeamPalette(mainHex: 0xE10613, deepHex: 0x5E0008, glowHex: 0xF0C987),
        "AVL": TeamPalette(mainHex: 0x7A1038, deepHex: 0x2E0516, glowHex: 0x8FC3EE),
        "BOU": TeamPalette(mainHex: 0xD6281B, deepHex: 0x1A0504, glowHex: 0xFFB3AB),
        "BRE": TeamPalette(mainHex: 0xE30613, deepHex: 0x4A0208, glowHex: 0xFFD23F),
        "BHA": TeamPalette(mainHex: 0x0A5BC4, deepHex: 0x04224D, glowHex: 0xFFD400),
        "CHE": TeamPalette(mainHex: 0x0A4BA0, deepHex: 0x041F4A, glowHex: 0xE8B93A),
        "COV": TeamPalette(mainHex: 0x3F9FC4, deepHex: 0x10335A, glowHex: 0xBFEAFF),
        "CRY": TeamPalette(mainHex: 0x1B55B5, deepHex: 0x0A1F4D, glowHex: 0xE5384F),
        "FUL": TeamPalette(mainHex: 0x2B2B33, deepHex: 0x08080A, glowHex: 0xE4E6EB),
        "HUL": TeamPalette(mainHex: 0xE8890E, deepHex: 0x1B1006, glowHex: 0xFFE08A),
        "IPS": TeamPalette(mainHex: 0x1F5FCC, deepHex: 0x0A2250, glowHex: 0xEAF2FF),
        "LEE": TeamPalette(mainHex: 0x2147A0, deepHex: 0x091632, glowHex: 0xFFD84D),
        "LIV": TeamPalette(mainHex: 0xC8102E, deepHex: 0x4A0612, glowHex: 0x2ED1BE),
        "MNC": TeamPalette(mainHex: 0x4A93CC, deepHex: 0x102B52, glowHex: 0xE3F2FF),
        "MAN": TeamPalette(mainHex: 0xD3201A, deepHex: 0x3A0806, glowHex: 0xFFD92E),
        "NEW": TeamPalette(mainHex: 0x2F2F36, deepHex: 0x08080A, glowHex: 0xC9CED6),
        "NFO": TeamPalette(mainHex: 0xD01020, deepHex: 0x3E040A, glowHex: 0xFFE0E0),
        "SUN": TeamPalette(mainHex: 0xE01A2D, deepHex: 0x32060C, glowHex: 0xFFFFFF),
        "TOT": TeamPalette(mainHex: 0x1B2C6B, deepHex: 0x080F2B, glowHex: 0xD8DEEA),
    ]

    /// 구단 코드("EVE" 등)로 찾는다. 표에 없으면 에버턴 색.
    public static func of(code: String?) -> TeamPalette {
        guard let code else { return everton }
        return table[code.uppercased()] ?? everton
    }

    public static func of(_ club: Club?) -> TeamPalette { of(code: club?.code) }

    static func blend(_ a: UInt32, _ b: UInt32, _ t: Double) -> UInt32 {
        func channel(_ shift: UInt32) -> UInt32 {
            let x = Double((a >> shift) & 0xFF), y = Double((b >> shift) & 0xFF)
            return UInt32((x + (y - x) * t).rounded()) << shift
        }
        return channel(16) | channel(8) | channel(0)
    }
}

private struct TeamPaletteKey: EnvironmentKey {
    static let defaultValue = TeamPalette.everton
}

public extension EnvironmentValues {
    /// 지금 화면의 구단 색. 선수·구단 화면 맨 위에서 `.environment(\.teamPalette, ...)` 로 정한다.
    var teamPalette: TeamPalette {
        get { self[TeamPaletteKey.self] }
        set { self[TeamPaletteKey.self] = newValue }
    }
}
