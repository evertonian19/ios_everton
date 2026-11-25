import SwiftUI

// MARK: - 스타디움 조명

/// 히어로 뒤에서 천천히 흔들리는 조명 빛줄기 2개와 반짝이는 별빛 점.
/// 모션 줄이기가 켜져 있으면 멈춘 채 한 장면만 보여 준다.
public struct StadiumLights: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init() {}

    private static let sparks: [(x: Double, y: Double, phase: Double)] = [
        (0.12, 0.22, 0.0), (0.30, 0.68, 1.3), (0.47, 0.18, 2.1), (0.63, 0.74, 0.7),
        (0.78, 0.30, 1.8), (0.90, 0.62, 2.6), (0.55, 0.45, 3.4),
    ]

    public var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { context in
            let t = reduceMotion ? 0 : context.date.timeIntervalSinceReferenceDate
            GeometryReader { proxy in
                let size = proxy.size
                ZStack {
                    beam(angle: -22 + sin(t * 0.45) * 7, x: size.width * 0.18, size: size)
                    beam(angle: 22 + sin(t * 0.38 + 1.7) * 7, x: size.width * 0.82, size: size)
                    ForEach(Self.sparks.indices, id: \.self) { index in
                        let spark = Self.sparks[index]
                        Circle()
                            .fill(Color.white)
                            .frame(width: 2.5, height: 2.5)
                            .opacity(0.25 + 0.55 * max(0, sin(t * 1.6 + spark.phase)))
                            .position(x: size.width * spark.x, y: size.height * spark.y)
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func beam(angle: Double, x: CGFloat, size: CGSize) -> some View {
        Rectangle()
            .fill(LinearGradient(colors: [Color.white.opacity(0.26), Color.white.opacity(0)], startPoint: .top, endPoint: .bottom))
            .frame(width: size.width * 0.22, height: size.height * 1.8)
            .blur(radius: 10)
            .rotationEffect(.degrees(angle), anchor: .top)
            .position(x: x, y: size.height * 0.9)
    }
}

// MARK: - 포일 반짝임

struct ShimmerModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content.overlay {
            if !reduceMotion {
                TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
                    let t = context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 3.6)
                    let progress = min(t / 1.4, 1)
                    GeometryReader { proxy in
                        LinearGradient(colors: [.clear, Color.white.opacity(0.6), .clear], startPoint: .leading, endPoint: .trailing)
                            .frame(width: proxy.size.width * 0.5)
                            .offset(x: proxy.size.width * (-0.6 + 1.7 * progress))
                    }
                }
                .mask(content)
                .allowsHitTesting(false)
            }
        }
    }
}

// MARK: - 글로우

struct GlowModifier: ViewModifier {
    let color: Color
    let active: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulse = false

    func body(content: Content) -> some View {
        content
            .shadow(color: active ? color.opacity(pulse ? 0.85 : 0.45) : .clear, radius: pulse ? 12 : 6)
            .shadow(color: active ? color.opacity(0.35) : .clear, radius: 2)
            .onChange(of: active, initial: true) { _, isActive in
                guard isActive, !reduceMotion else { pulse = false; return }
                withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) { pulse = true }
            }
    }
}

// MARK: - 등장

struct RiseModifier: ViewModifier {
    let delay: Double
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : 14)
            .onAppear {
                if reduceMotion { shown = true } else {
                    withAnimation(.spring(duration: 0.5, bounce: 0.2).delay(delay)) { shown = true }
                }
            }
    }
}

public extension View {
    /// 금속 포일처럼 흰 띠가 가끔 훑고 지나간다.
    func evShimmer() -> some View { modifier(ShimmerModifier()) }
    /// 색 번짐. `active` 가 켜져 있으면 숨 쉬듯 커졌다 작아진다.
    func evGlow(_ color: Color, active: Bool = true) -> some View { modifier(GlowModifier(color: color, active: active)) }
    /// 아래에서 떠오르며 나타난다. 행마다 `delay` 를 달리 주면 차례로 등장한다.
    func evRise(delay: Double = 0) -> some View { modifier(RiseModifier(delay: delay)) }
}

// MARK: - 숫자 카운트업

/// 값이 바뀌면 프레임마다 보간된 정수를 그린다.
private struct CountingText: View, Animatable {
    var value: Double
    let format: (Int) -> String

    var animatableData: Double {
        get { value }
        set { value = newValue }
    }

    var body: some View { Text(format(Int(value.rounded()))) }
}

/// 0 에서 목표 값까지 올라가는 숫자. 글꼴·색은 바깥에서 `.font` / `.foregroundStyle` 로 준다.
public struct CountUpText: View {
    let target: Int
    let format: (Int) -> String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown: Double = 0

    public init(_ target: Int, format: @escaping (Int) -> String = { String($0) }) {
        self.target = target
        self.format = format
    }

    public var body: some View {
        CountingText(value: shown, format: format)
            .monospacedDigit()
            .onAppear { run() }
            .onChange(of: target) { _, _ in run() }
    }

    private func run() {
        if reduceMotion { shown = Double(target) } else {
            withAnimation(.easeOut(duration: 1.0)) { shown = Double(target) }
        }
    }
}

// MARK: - 기록 칩

/// 로열 블루 히어로 위에 올리는 반투명 기록 칩. `highlight` 면 금색 테두리와 글로우.
public struct StatTile: View {
    let value: Int
    let label: String
    let icon: String?
    let highlight: Bool
    let compact: Bool

    public init(value: Int, label: String, icon: String? = nil, highlight: Bool = false, compact: Bool = false) {
        self.value = value
        self.label = label
        self.icon = icon
        self.highlight = highlight
        self.compact = compact
    }

    public var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 4) {
                if let icon {
                    Image(systemName: icon).font(.caption.weight(.bold))
                }
                CountUpText(value).font(.system(size: compact ? 18 : 26, weight: .heavy, design: .rounded))
            }
            .foregroundStyle(highlight ? Theme.gold : Color.white)
            Text(label).font(.caption2.weight(.semibold)).foregroundStyle(Theme.onBrand2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, compact ? 6 : 8)
        .background(Color.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(highlight ? Theme.gold.opacity(0.85) : Color.white.opacity(0.18), lineWidth: 1)
        )
        .evGlow(Theme.gold, active: highlight)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label) \(value)")
    }
}
