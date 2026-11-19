import SwiftUI
import EvCore

/// 평점에 따라 카드 등급(색)이 정해진다.
public enum CardTier {
    case bronze, silver, gold, special

    public init(rating: Double?) {
        switch rating ?? 0 {
        case ..<6.4: self = .bronze
        case ..<6.9: self = .silver
        case ..<7.4: self = .gold
        default: self = .special
        }
    }

    var colors: [Color] {
        switch self {
        case .bronze: return [Color(hex: 0x8C5A35), Color(hex: 0x4E2F1B)]
        case .silver: return [Color(hex: 0xC4CCD8), Color(hex: 0x6E7A90)]
        case .gold: return [Color(hex: 0xF3D27A), Color(hex: 0xB07D1E)]
        case .special: return [Color(hex: 0x35E0C3), Color(hex: 0x0E6FD8)]
        }
    }

    var ink: Color {
        switch self {
        case .bronze: return .white
        default: return Color(hex: 0x0B1330)
        }
    }
}

public struct ShieldShape: Shape {
    public init() {}

    public func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height, r = w * 0.14
        var p = Path()
        p.move(to: CGPoint(x: r, y: 0))
        p.addLine(to: CGPoint(x: w - r, y: 0))
        p.addQuadCurve(to: CGPoint(x: w, y: r), control: CGPoint(x: w, y: 0))
        p.addLine(to: CGPoint(x: w, y: h * 0.76))
        p.addQuadCurve(to: CGPoint(x: w / 2, y: h), control: CGPoint(x: w, y: h * 0.92))
        p.addQuadCurve(to: CGPoint(x: 0, y: h * 0.76), control: CGPoint(x: 0, y: h * 0.92))
        p.addLine(to: CGPoint(x: 0, y: r))
        p.addQuadCurve(to: CGPoint(x: r, y: 0), control: CGPoint(x: 0, y: 0))
        p.closeSubpath()
        return p
    }
}

/// FIFA/FM 풍 선수 카드: 평점이 높을수록 등급 색이 달라진다.
public struct PlayerCard: View {
    let player: Player

    public init(_ player: Player) { self.player = player }

    public var body: some View {
        let tier = CardTier(rating: player.stats?.rating)
        ZStack {
            ShieldShape().fill(LinearGradient(colors: tier.colors, startPoint: .topLeading, endPoint: .bottomTrailing))
            // 번호 워터마크
            if let number = player.number {
                Text("\(number)")
                    .font(.system(size: 78, weight: .black, design: .rounded))
                    .foregroundStyle(tier.ink.opacity(0.10))
                    .offset(x: 14, y: 8)
            }
            ShieldShape().stroke(.white.opacity(0.35), lineWidth: 1.5)
            VStack(spacing: 0) {
                HStack(alignment: .top) {
                    VStack(spacing: 0) {
                        Text(Fmt.rating(player.stats?.rating))
                            .font(.system(size: 24, weight: .black, design: .rounded))
                        Text(player.position.short).font(.system(size: 11, weight: .heavy))
                    }
                    .foregroundStyle(tier.ink)
                    Spacer()
                    PlayerPhoto(url: player.photoURL, name: player.name, size: 58)
                }
                Spacer(minLength: 2)
                Text(player.shortName.uppercased())
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(tier.ink)
                    .lineLimit(1).minimumScaleFactor(0.6)
                Rectangle().fill(tier.ink.opacity(0.35)).frame(height: 1).padding(.vertical, 3)
                HStack(spacing: 10) {
                    miniStat("골", player.stats?.goals)
                    miniStat("도움", player.stats?.assists)
                    miniStat("출전", player.stats?.appearances)
                }
                .foregroundStyle(tier.ink)
                .padding(.bottom, 14)
            }
            .padding(.horizontal, 12).padding(.top, 12)
        }
        .aspectRatio(0.78, contentMode: .fit)
        .shadow(color: tier.colors[0].opacity(0.35), radius: 8, y: 4)
    }

    private func miniStat(_ label: String, _ value: Int?) -> some View {
        VStack(spacing: 0) {
            Text(value.map(String.init) ?? "-").font(.system(size: 13, weight: .black, design: .rounded))
            Text(label).font(.system(size: 8, weight: .semibold)).opacity(0.75)
        }
    }
}
