import SwiftUI
import EvCore

// MARK: - 카드 (제목이 있는 흰 카드)

/// 제목 + 본문. 헤더 바 없이 카드 안 첫 줄의 굵은 제목으로 구획을 나눈다.
public struct FMPanel<Content: View>: View {
    let title: String?
    let trailing: String?
    let content: Content

    public init(_ title: String? = nil, trailing: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.trailing = trailing
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let title {
                HStack {
                    Text(title).font(.subheadline.weight(.bold)).foregroundStyle(Theme.textPrimary)
                    Spacer()
                    if let trailing { Text(trailing).font(.caption).foregroundStyle(Theme.textSecondary) }
                }
            }
            content.frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: Theme.shadow, radius: 3, y: 1)
    }
}

public struct CardModifier: ViewModifier {
    var highlighted: Bool
    public func body(content: Content) -> some View {
        content
            .padding(14)
            .background(highlighted ? Theme.surfaceHigh : Theme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: Theme.shadow, radius: 3, y: 1)
    }
}

public extension View {
    func evCard(highlighted: Bool = false) -> some View { modifier(CardModifier(highlighted: highlighted)) }

    /// 로열 블루 내비게이션 바 + 흰 제목·뒤로 버튼, 흰 탭 바. 각 화면의 스크롤 뷰에 한 번 붙인다.
    func evBrandBars() -> some View {
        self
            .toolbarBackground(Theme.brand, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Theme.surface, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
    }

    /// 로열 블루 히어로 영역(다음 경기·선수·구단·경기 상단).
    func evHero() -> some View {
        self
            .background {
                ZStack {
                    Theme.stadiumGradient
                    StadiumLights()
                }
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(LinearGradient(colors: [Theme.gold.opacity(0.7), .clear], startPoint: .top, endPoint: .center), lineWidth: 1)
            )
            .shadow(color: Theme.shadow, radius: 3, y: 1)
    }
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
            Text(text).font(.caption.weight(.heavy)).tracking(0.6).foregroundStyle(Theme.textSecondary)
            Spacer()
            if let trailing { Text(trailing).font(.caption).foregroundStyle(Theme.blue) }
        }
        .padding(.horizontal, 2)
    }
}

// MARK: - 밑줄 탭 (서브 메뉴)

public struct FMTabs<Value: Hashable>: View {
    let items: [(Value, String)]
    @Binding var selection: Value
    @Namespace private var underline

    public init(_ items: [(Value, String)], selection: Binding<Value>) {
        self.items = items
        self._selection = selection
    }

    public var body: some View {
        HStack(spacing: 0) {
            ForEach(items.indices, id: \.self) { index in
                let item = items[index]
                Button { withAnimation(.snappy(duration: 0.2)) { selection = item.0 } } label: {
                    VStack(spacing: 6) {
                        Text(item.1)
                            .font(.footnote.weight(.bold))
                            .foregroundStyle(selection == item.0 ? Theme.textPrimary : Theme.textSecondary)
                        ZStack {
                            Rectangle().fill(Color.clear).frame(height: 2)
                            if selection == item.0 {
                                Rectangle().fill(Theme.blue).frame(height: 2).matchedGeometryEffect(id: "tab-underline", in: underline)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 6)
        .overlay(alignment: .bottom) { Divider().overlay(Theme.line) }
        .sensoryFeedback(.selection, trigger: selection)
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

/// 선수 사진 자리. ESPN 은 사진을 주지 않으므로 이니셜 아바타가 기본이고, 사진 URL 이 있으면(API-Football) 사진을 쓴다.
public struct PlayerPhoto: View {
    let url: URL?
    let name: String
    let size: CGFloat
    let ringed: Bool

    public init(url: URL?, name: String, size: CGFloat = 64, ringed: Bool = false) {
        self.url = url
        self.name = name
        self.size = size
        self.ringed = ringed
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
                    Theme.heroGradient
                    Text(initials).font(.system(size: size * 0.36, weight: .heavy)).foregroundStyle(Theme.onBrand)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.14, style: .continuous))
        .overlay {
            if ringed {
                RoundedRectangle(cornerRadius: size * 0.14, style: .continuous)
                    .strokeBorder(LinearGradient(colors: [Theme.gold, Color.white.opacity(0.85), Theme.gold], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 2.5)
            }
        }
        .evGlow(Theme.gold, active: ringed)
    }
}

public struct FlagImage: View {
    let url: URL?

    public init(_ url: URL?) { self.url = url }

    public var body: some View {
        AsyncImage(url: url) { phase in
            if let image = phase.image { image.resizable().scaledToFill() } else { Color.clear }
        }
        .frame(width: 18, height: 12)
        .clipShape(RoundedRectangle(cornerRadius: 2))
    }
}

// MARK: - 폼 / 포지션

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

    private var label: String {
        switch result {
        case .win: return "승"
        case .draw: return "무"
        case .loss: return "패"
        case nil: return "·"
        }
    }

    public var body: some View {
        Text(label)
            .font(.caption.weight(.heavy))
            .foregroundStyle(.white)
            .frame(width: 24, height: 22)
            .background(color, in: RoundedRectangle(cornerRadius: 4, style: .continuous))
    }
}

public struct PositionTag: View {
    let position: Position

    public init(_ position: Position) { self.position = position }

    public var body: some View {
        Text(position.short)
            .font(.system(size: 9.5, weight: .black))
            .foregroundStyle(Color(hex: 0x0B1220))
            .padding(.horizontal, 4).padding(.vertical, 1.5)
            .frame(minWidth: 24)
            .background(Theme.positionColor(position.short), in: RoundedRectangle(cornerRadius: 3, style: .continuous))
            .shadow(color: Theme.positionColor(position.short).opacity(0.55), radius: 4)
    }
}

// MARK: - 지표 막대 (속성 줄)

/// 라벨 · 색이 입혀진 막대 · 숫자. value 는 0...1 로 정규화한 값, detail 은 실제 수치 문구.
public struct AttributeBar: View {
    let label: String
    let value: Double
    let detail: String
    @State private var grown = false

    public init(label: String, value: Double, detail: String) {
        self.label = label
        self.value = value
        self.detail = detail
    }

    public var body: some View {
        let color = Theme.attributeColor(value)
        HStack(spacing: 8) {
            Text(label).font(.caption).foregroundStyle(Theme.textSecondary).frame(width: 70, alignment: .leading)
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.surfaceHigh)
                    Capsule()
                        .fill(LinearGradient(colors: [color.opacity(0.65), color], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(proxy.size.width * (grown ? value : 0), 4))
                        .overlay(alignment: .trailing) {
                            Circle().fill(Color.white).frame(width: 4, height: 4).padding(.trailing, 1)
                                .shadow(color: color, radius: 3).opacity(grown ? 1 : 0)
                        }
                }
            }
            .frame(height: 6)
            Text(detail).font(.caption.weight(.bold)).foregroundStyle(color).frame(width: 52, alignment: .trailing)
        }
        .onAppear { withAnimation(.easeOut(duration: 0.6)) { grown = true } }
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
                    Capsule().fill(Theme.draw.opacity(0.45))
                        .frame(width: max(proxy.size.width * (grown ? line.away / total : 0.5) - 1.5, 4))
                }
            }
            .frame(height: 5)
            .onAppear { withAnimation(.spring(duration: 0.7)) { grown = true } }
        }
    }
}
