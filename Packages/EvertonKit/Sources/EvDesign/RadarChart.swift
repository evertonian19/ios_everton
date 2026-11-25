import SwiftUI

/// 0...1 로 정규화된 값들을 다각형으로 그리는 레이더 차트.
public struct RadarShape: Shape {
    public var values: [Double]

    public init(values: [Double]) { self.values = values }

    public func path(in rect: CGRect) -> Path {
        var path = Path()
        guard values.count >= 3 else { return path }
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        for (index, value) in values.enumerated() {
            let angle = -Double.pi / 2 + 2 * Double.pi * Double(index) / Double(values.count)
            let r = radius * CGFloat(min(max(value, 0.04), 1))
            let point = CGPoint(x: center.x + r * CGFloat(cos(angle)), y: center.y + r * CGFloat(sin(angle)))
            if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }
}

public struct RadarChart: View {
    let labels: [String]
    let values: [Double]
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var grown = false

    public init(labels: [String], values: [Double]) {
        self.labels = labels
        self.values = values
    }

    private func point(_ index: Int, scale: CGFloat, in size: CGSize) -> CGPoint {
        let angle = -Double.pi / 2 + 2 * Double.pi * Double(index) / Double(max(labels.count, 1))
        let radius = min(size.width, size.height) / 2 * scale
        return CGPoint(x: size.width / 2 + radius * CGFloat(cos(angle)),
                       y: size.height / 2 + radius * CGFloat(sin(angle)))
    }

    public var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack {
                ForEach([0.33, 0.66, 1.0], id: \.self) { ring in
                    RadarShape(values: Array(repeating: ring, count: max(labels.count, 3)))
                        .stroke(Theme.line.opacity(0.7), lineWidth: 1)
                }
                ZStack {
                    RadarShape(values: values)
                        .fill(LinearGradient(colors: [Theme.blue.opacity(0.55), Theme.gold.opacity(0.25)], startPoint: .top, endPoint: .bottom))
                    RadarShape(values: values)
                        .stroke(Theme.blue, style: StrokeStyle(lineWidth: 2, lineJoin: .round))
                    ForEach(values.indices, id: \.self) { index in
                        Circle().fill(Theme.gold).frame(width: 7, height: 7)
                            .shadow(color: Theme.gold.opacity(0.9), radius: 4)
                            .position(point(index, scale: CGFloat(min(max(values[index], 0.04), 1)), in: size))
                    }
                }
                .scaleEffect(grown ? 1 : 0.05)
                .opacity(grown ? 1 : 0)
                ForEach(labels.indices, id: \.self) { index in
                    Text(labels[index])
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Theme.textSecondary)
                        .position(point(index, scale: 1.18, in: size))
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .padding(24)
        .onAppear {
            if reduceMotion { grown = true } else { withAnimation(.spring(duration: 0.9, bounce: 0.25)) { grown = true } }
        }
    }
}
