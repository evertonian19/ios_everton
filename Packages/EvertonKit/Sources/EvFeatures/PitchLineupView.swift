import SwiftUI
import EvCore
import EvDesign

/// grid("행:열", 1행 = 골키퍼)를 이용해 선수들을 피치 위에 배치한다. ESPN 은 포메이션 슬롯으로 계산해 준다.
struct PitchLineupView: View {
    let lineup: TeamLineup

    private struct Placed: Identifiable {
        let player: LineupPlayer
        let row: Int
        let col: Int
        let rowCount: Int
        let colCount: Int
        var id: Int { player.id }
    }

    private var placed: [Placed] {
        var rows: [Int: [(LineupPlayer, Int)]] = [:]
        for player in lineup.starters {
            let parts = (player.grid ?? "").split(separator: ":").compactMap { Int($0) }
            guard parts.count == 2 else { continue }
            rows[parts[0], default: []].append((player, parts[1]))
        }
        let rowCount = rows.keys.max() ?? 1
        return rows.flatMap { row, entries in
            entries.map { Placed(player: $0.0, row: row, col: $0.1, rowCount: rowCount, colCount: entries.count) }
        }
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                PitchBackground()
                ForEach(placed) { item in
                    PitchPlayerView(player: item.player)
                        .position(
                            x: proxy.size.width * CGFloat(item.col) / CGFloat(item.colCount + 1),
                            y: proxy.size.height * (1 - (CGFloat(item.row) - 0.5) / CGFloat(item.rowCount)))
                }
            }
        }
        .aspectRatio(0.74, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(Theme.line, lineWidth: 1))
    }
}

private struct PitchPlayerView: View {
    let player: LineupPlayer

    var body: some View {
        VStack(spacing: 2) {
            Text(player.number.map(String.init) ?? "")
                .font(.system(size: 13, weight: .heavy))
                .foregroundStyle(Color(hex: 0x0B1220))
                .frame(width: 28, height: 28)
                .background(.white, in: Circle())
            Text(player.shortName)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 5).padding(.vertical, 1)
                .background(.black.opacity(0.45), in: Capsule())
                .lineLimit(1)
        }
        .frame(width: 70)
    }
}

private struct PitchBackground: View {
    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            ZStack {
                LinearGradient(colors: [Color(hex: 0x1C6B3A), Color(hex: 0x15532E)], startPoint: .top, endPoint: .bottom)
                // 잔디 줄무늬
                VStack(spacing: 0) {
                    ForEach(0..<8, id: \.self) { index in
                        Rectangle().fill(index % 2 == 0 ? Color.white.opacity(0.04) : Color.clear)
                    }
                }
                Path { path in
                    let inset: CGFloat = 10
                    path.addRect(CGRect(x: inset, y: inset, width: w - inset * 2, height: h - inset * 2))
                    path.move(to: CGPoint(x: inset, y: h / 2))
                    path.addLine(to: CGPoint(x: w - inset, y: h / 2))
                    path.addEllipse(in: CGRect(x: w / 2 - 34, y: h / 2 - 34, width: 68, height: 68))
                    // 페널티 박스
                    path.addRect(CGRect(x: w * 0.22, y: inset, width: w * 0.56, height: h * 0.14))
                    path.addRect(CGRect(x: w * 0.22, y: h - inset - h * 0.14, width: w * 0.56, height: h * 0.14))
                    // 골 에어리어
                    path.addRect(CGRect(x: w * 0.36, y: inset, width: w * 0.28, height: h * 0.06))
                    path.addRect(CGRect(x: w * 0.36, y: h - inset - h * 0.06, width: w * 0.28, height: h * 0.06))
                }
                .stroke(Color.white.opacity(0.35), lineWidth: 1.5)
            }
        }
    }
}
