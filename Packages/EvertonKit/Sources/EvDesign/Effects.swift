import SwiftUI

// MARK: - 스타디움 조명

/// 히어로·피치 뒤의 조명 연출: 흔들리는 빛줄기 2개, 흐르는 오로라 띠, 아래에서 떠오르는 스파크(팀 발광색).
/// 모션 줄이기가 켜져 있으면 멈춘 채 한 장면만 보여 준다.
public struct StadiumLights: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let palette: TeamPalette
    let sparks: Bool
    let aurora: Bool

    public init(palette: TeamPalette = .everton, sparks: Bool = true, aurora: Bool = true) {
        self.palette = palette
        self.sparks = sparks
        self.aurora = aurora
    }

    private struct Spark {
        let x: Double
        let speed: Double
        let phase: Double
        let size: CGFloat
    }

    private static let particles: [Spark] = (0..<16).map { i in
        Spark(x: (Double(i) * 0.37 + 0.11).truncatingRemainder(dividingBy: 1),
              speed: 0.09 + Double(i % 5) * 0.03,
              phase: Double(i) * 0.137,
              size: 2.5 + CGFloat(i % 4))
    }

    public var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { context in
            let t = reduceMotion ? 0 : context.date.timeIntervalSinceReferenceDate
            GeometryReader { proxy in
                let size = proxy.size
                ZStack {
                    if aurora {
                        Rectangle()
                            .fill(LinearGradient(colors: [.clear, palette.glow.opacity(0.38), .clear], startPoint: .leading, endPoint: .trailing))
                            .frame(width: size.width * 0.45, height: size.height * 2.2)
                            .rotationEffect(.degrees(18))
                            .offset(x: CGFloat(sin(t * 0.55)) * size.width * 0.55)
                            .blendMode(.screen)
                    }
                    beam(angle: -22 + sin(t * 0.45) * 7, x: size.width * 0.18, size: size)
                    beam(angle: 22 + sin(t * 0.38 + 1.7) * 7, x: size.width * 0.82, size: size)
                    if sparks {
                        ForEach(Self.particles.indices, id: \.self) { index in
                            let spark = Self.particles[index]
                            let progress = (t * spark.speed + spark.phase).truncatingRemainder(dividingBy: 1)
                            Circle()
                                .fill(palette.glow)
                                .frame(width: spark.size, height: spark.size)
                                .shadow(color: palette.glow, radius: 4)
                                .opacity(reduceMotion ? 0.5 : sin(progress * .pi))
                                .position(x: size.width * spark.x + CGFloat(sin(t * 1.3 + spark.phase * 9)) * 6,
                                          y: size.height * CGFloat(1.02 - progress))
                        }
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func beam(angle: Double, x: CGFloat, size: CGSize) -> some View {
        Rectangle()
            .fill(LinearGradient(colors: [Color.white.opacity(0.28), Color.white.opacity(0)], startPoint: .top, endPoint: .bottom))
            .frame(width: size.width * 0.22, height: size.height * 1.8)
            .blur(radius: 10)
            .rotationEffect(.degrees(angle), anchor: .top)
            .position(x: x, y: size.height * 0.9)
    }
}

/// 카드 테두리를 따라 도는 홀로그램 포일.
struct FoilBorder: View {
    let color: Color
    let cornerRadius: CGFloat
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { context in
            let angle = reduceMotion ? 40.0 : context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 5) / 5 * 360
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(
                    AngularGradient(colors: [color, color.opacity(0.05), Color.white.opacity(0.9), color.opacity(0.05), color],
                                    center: .center, angle: .degrees(angle)),
                    lineWidth: 2)
        }
        .allowsHitTesting(false)
    }
}

struct HeroModifier: ViewModifier {
    @Environment(\.teamPalette) private var palette

    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    palette.gradient
                    RadialGradient(colors: [palette.glow.opacity(0.28), .clear], center: .topTrailing, startRadius: 0, endRadius: 240)
                }
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .shadow(color: palette.main.opacity(0.45), radius: 12, y: 4)
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

struct DropModifier: ViewModifier {
    let delay: Double
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .scaleEffect(shown ? 1 : 0.6)
            .offset(y: shown ? 0 : -60)
            .brightness(shown ? 0 : 0.8)
            .onAppear {
                if reduceMotion { shown = true } else {
                    withAnimation(.spring(duration: 0.65, bounce: 0.4).delay(delay)) { shown = true }
                }
            }
    }
}

public extension View {
    /// 위에서 떨어지며 번쩍 나타난다(베스트 11 선수 칸).
    func evDrop(delay: Double = 0) -> some View { modifier(DropModifier(delay: delay)) }
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

/// 히어로 위에 올리는 반투명 기록 칩. `highlight` 면 팀 발광색 테두리·글로우, 숫자가 다 올라가면 반짝 버스트.
public struct StatTile: View {
    let value: Int
    let label: String
    let icon: String?
    let highlight: Bool
    let compact: Bool
    let tint: Color?
    @Environment(\.teamPalette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var flash: Double = 0
    @State private var flashScale: CGFloat = 0.3

    public init(value: Int, label: String, icon: String? = nil, highlight: Bool = false, compact: Bool = false, tint: Color? = nil) {
        self.value = value
        self.label = label
        self.icon = icon
        self.highlight = highlight
        self.compact = compact
        self.tint = tint
    }

    private var accent: Color { tint ?? palette.glow }

    public var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 4) {
                if let icon {
                    Image(systemName: icon).font(.caption.weight(.bold))
                }
                CountUpText(value).font(.system(size: compact ? 18 : 26, weight: .heavy, design: .rounded))
            }
            .foregroundStyle(Color.white)
            .shadow(color: highlight ? accent : .clear, radius: 6)
            Text(label).font(.caption2.weight(.semibold)).foregroundStyle(Color.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, compact ? 6 : 8)
        .background {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(LinearGradient(
                    colors: highlight ? [accent.opacity(0.5), Color.white.opacity(0.05)] : [Color.white.opacity(0.22), Color.white.opacity(0.06)],
                    startPoint: .topLeading, endPoint: .bottomTrailing))
        }
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(highlight ? accent : Color.white.opacity(0.28), lineWidth: 1)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(RadialGradient(colors: [Color.white, accent.opacity(0.6), .clear], center: .center, startRadius: 0, endRadius: 40))
                .opacity(flash)
                .scaleEffect(flashScale)
                .allowsHitTesting(false)
        }
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .evGlow(accent, active: highlight)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label) \(value)")
        .task {
            guard !reduceMotion else { return }
            try? await Task.sleep(for: .seconds(1.0))
            flash = 0.9
            flashScale = 0.3
            try? await Task.sleep(for: .milliseconds(30))
            withAnimation(.easeOut(duration: 0.7)) {
                flash = 0
                flashScale = 1.8
            }
        }
    }
}

// MARK: - 골 세리머니

/// 골 개수만큼 축구공이 하나씩 튀어 오른다(최대 10개, 넘으면 +n).
public struct GoalPips: View {
    let count: Int
    @Environment(\.teamPalette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false

    public init(_ count: Int) { self.count = count }

    public var body: some View {
        if count > 0 {
            HStack(spacing: 3) {
                ForEach(0..<min(count, 10), id: \.self) { index in
                    Image(systemName: "soccerball")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.white)
                        .shadow(color: palette.glow, radius: 5)
                        .scaleEffect(shown ? 1 : 0.2)
                        .opacity(shown ? 1 : 0)
                        .offset(y: shown ? 0 : -18)
                        .rotationEffect(.degrees(shown ? 0 : -120))
                        .animation(reduceMotion ? nil : .spring(duration: 0.5, bounce: 0.45).delay(0.9 + Double(index) * 0.09), value: shown)
                }
                if count > 10 {
                    Text("+\(count - 10)").font(.caption.weight(.heavy)).foregroundStyle(palette.glow)
                }
                Spacer(minLength: 0)
            }
            .onAppear { shown = true }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("골 \(count)")
        }
    }
}
