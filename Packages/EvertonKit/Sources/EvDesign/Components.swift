import SwiftUI
import EvCore

// MARK: - 카드 / 제목

public struct CardModifier: ViewModifier {
    var highlighted: Bool
    public func body(content: Content) -> some View {
        content
            .padding(14)
            .background(highlighted ? Theme.surfaceHigh : Theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Theme.line.opacity(0.6), lineWidth: 1))
    }
}

public extension View {
    func evCard(highlighted: Bool = false) -> some View { modifier(CardModifier(highlighted: highlighted)) }
}

public struct SectionTitle: View {
    let text: String
    let trailing: String?

    public init(_ text: String, trailing: String? = nil) {
        self.text = text
        self.trailing = trailing
    }

    public var body: some View {
        HStack {
            Text(text.uppercased())
                .font(.caption.weight(.heavy))
                .tracking(1.2)
                .foregroundStyle(Theme.textSecondary)
            Spacer()
            if let trailing {
                Text(trailing).font(.caption).foregroundStyle(Theme.blue)
            }
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - 이미지

public struct ClubLogo: View {
    let url: URL?
    let size: CGFloat

    public init(url: URL?, size: CGFloat = 40) {
        self.url = url
        self.size = size
    }

    public var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image): image.resizable().scaledToFit()
            default: Image(systemName: "shield.lefthalf.filled").resizable().scaledToFit().foregroundStyle(Theme.line)
            }
        }
        .frame(width: size, height: size)
    }
}

public struct PlayerPhoto: View {
    let url: URL?
    let name: String
    let size: CGFloat

    public init(url: URL?, name: String, size: CGFloat = 64) {
        self.url = url
        self.name = name
        self.size = size
    }

    private var initials: String {
        name.split(separator: " ").compactMap { $0.first }.prefix(2).map(String.init).joined()
    }

    public var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image): image.resizable().scaledToFill()
            default:
                ZStack {
                    Theme.surfaceHigh
                    Text(initials).font(.system(size: size * 0.34, weight: .heavy)).foregroundStyle(Theme.textSecondary)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().stroke(Theme.line, lineWidth: 1.5))
    }
}

// MARK: - 폼 / 평점

public struct FormBadge: View {
    let result: MatchResult?

    public init(_ result: MatchResult?) { self.result = result }

    private var color: Color {
        switch result {
        case .win: return Theme.win
        case .draw: return Theme.draw
        case .loss: return Theme.loss
        case nil: return Theme.line
        }
    }

    public var body: some View {
        Text(result?.letter ?? "·")
            .font(.caption.weight(.heavy))
            .foregroundStyle(.black.opacity(0.8))
            .frame(width: 26, height: 26)
            .background(color, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

public struct RatingRing: View {
    let rating: Double?
    let size: CGFloat
    @State private var shown = false

    public init(_ rating: Double?, size: CGFloat = 44) {
        self.rating = rating
        self.size = size
    }

    public var body: some View {
        let color = Theme.ratingColor(rating)
        ZStack {
            Circle().stroke(Theme.line, lineWidth: size * 0.09)
            Circle()
                .trim(from: 0, to: shown ? min(max((rating ?? 0) / 10, 0), 1) : 0)
                .stroke(color, style: StrokeStyle(lineWidth: size * 0.09, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text(Fmt.rating(rating))
                .font(.system(size: size * 0.34, weight: .heavy, design: .rounded))
                .foregroundStyle(color)
        }
        .frame(width: size, height: size)
        .onAppear { withAnimation(.easeOut(duration: 0.9)) { shown = true } }
    }
}

public struct PositionTag: View {
    let position: Position

    public init(_ position: Position) { self.position = position }

    private var color: Color {
        switch position {
        case .goalkeeper: return Theme.gold
        case .defender: return Theme.blue
        case .midfielder: return Theme.win
        case .attacker: return Theme.loss
        }
    }

    public var body: some View {
        Text(position.short)
            .font(.system(size: 10, weight: .heavy))
            .foregroundStyle(.black.opacity(0.85))
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(color, in: Capsule())
    }
}

// MARK: - 통계 비교 막대

public struct StatCompareRow: View {
    let line: StatLine
    @State private var grown = false

    public init(_ line: StatLine) { self.line = line }

    public var body: some View {
        let total = max(line.home + line.away, 0.0001)
        VStack(spacing: 5) {
            HStack {
                Text(Fmt.stat(line.home, percent: line.isPercent)).fontWeight(.bold)
                Spacer()
                Text(line.label).foregroundStyle(Theme.textSecondary)
                Spacer()
                Text(Fmt.stat(line.away, percent: line.isPercent)).fontWeight(.bold)
            }
            .font(.footnote)
            .foregroundStyle(Theme.textPrimary)

            GeometryReader { proxy in
                HStack(spacing: 3) {
                    Capsule().fill(Theme.blue)
                        .frame(width: max(proxy.size.width * (grown ? line.home / total : 0.5) - 1.5, 4))
                    Capsule().fill(Theme.line)
                        .frame(width: max(proxy.size.width * (grown ? line.away / total : 0.5) - 1.5, 4))
                }
            }
            .frame(height: 6)
            .onAppear { withAnimation(.spring(duration: 0.7)) { grown = true } }
        }
    }
}
