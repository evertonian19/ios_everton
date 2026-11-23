import SwiftUI
import EvCore
import EvDesign

/// 구단 스쿼드 영역: 베스트 11(포메이션) → 후보 → 주요 전술. 에버턴 스쿼드 탭과 구단 상세가 함께 쓴다.
struct TeamSquadSection: View {
    @Environment(AppModel.self) private var model
    let clubID: Int
    let players: [Player]

    private var tactics: LoadState<TeamTactics> { model.tactics[clubID] ?? .idle }

    var body: some View {
        VStack(spacing: 10) {
            switch tactics {
            case .loaded(let t) where !t.xi.isEmpty:
                loaded(t)
            case .failed(let message):
                fallback(note: "베스트 11 을 만들지 못했어요. \(message)")
            default:
                fallback(note: "베스트 11 불러오는 중…")
            }
        }
        .task { await model.loadTactics(clubID) }
    }

    @ViewBuilder
    private func loaded(_ t: TeamTactics) -> some View {
        let used = Set(t.xi.map(\.id))
        let bench = players.filter { !used.contains($0.id) }
        FMPanel("베스트 11 · \(t.formation ?? "-")", trailing: "최근 \(t.opponents.count)경기 기준") {
            VStack(spacing: 6) {
                XIPitchView(xi: t.xi, players: players)
                Text("선수를 누르면 상세 정보 · 골·도움은 시즌 누적")
                    .font(.caption2).foregroundStyle(Theme.textSecondary)
            }
        }
        FMPanel("후보 · \(bench.count)명") { RosterTable(players: bench) }
        TacticsPanel(tactics: t)
    }

    /// 베스트 11 을 아직 못 만들었을 때: 지금까지처럼 전체 선수 표를 보여 준다.
    private func fallback(note: String) -> some View {
        FMPanel("스쿼드 · \(players.count)명") {
            VStack(alignment: .leading, spacing: 8) {
                Text(note).font(.caption).foregroundStyle(Theme.textSecondary)
                RosterTable(players: players)
            }
        }
    }
}

/// 베스트 11 을 포메이션 모양으로 배치한다. 선수 칸에는 골·도움만 보이고, 누르면 선수 상세로 이동한다.
struct XIPitchView: View {
    let xi: [XIPlayer]
    let players: [Player]

    private struct Placed: Identifiable {
        let player: XIPlayer
        let row: Int
        let col: Int
        let colCount: Int
        var id: Int { player.id }
    }

    private var placed: (items: [Placed], rowCount: Int) {
        var rows: [Int: [(XIPlayer, Int)]] = [:]
        for p in xi {
            let parts = p.grid.split(separator: ":").compactMap { Int($0) }
            guard parts.count == 2 else { continue }
            rows[parts[0], default: []].append((p, parts[1]))
        }
        let rowCount = rows.keys.max() ?? 1
        let items = rows.flatMap { row, entries in
            entries.map { Placed(player: $0.0, row: row, col: $0.1, colCount: entries.count) }
        }
        return (items, rowCount)
    }

    var body: some View {
        let layout = placed
        GeometryReader { proxy in
            ZStack {
                PitchBackground()
                ForEach(layout.items) { item in
                    XICell(xi: item.player, player: players.first { $0.id == item.player.id })
                        .position(
                            x: proxy.size.width * CGFloat(item.col) / CGFloat(item.colCount + 1),
                            y: proxy.size.height * (1 - (CGFloat(item.row) - 0.5) / CGFloat(layout.rowCount)))
                }
            }
        }
        .aspectRatio(0.72, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(Theme.line, lineWidth: 1))
    }
}

private struct XICell: View {
    let xi: XIPlayer
    let player: Player?

    private var stats: PlayerStats? { player?.stats }
    private var goals: String { stats.map { String($0.goals) } ?? "-" }
    private var assists: String { stats.map { String($0.assists) } ?? "-" }
    private var hasPoints: Bool { (stats?.goals ?? 0) + (stats?.assists ?? 0) > 0 }

    private var content: some View {
        VStack(spacing: 2) {
            Text(xi.number.map(String.init) ?? "")
                .font(.system(size: 13, weight: .heavy))
                .foregroundStyle(Color(hex: 0x0B1220))
                .frame(width: 28, height: 28)
                .background(.white, in: Circle())
            Text(xi.shortName)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 5).padding(.vertical, 1)
                .background(.black.opacity(0.45), in: Capsule())
                .lineLimit(1)
            Text("⚽\(goals) 🅰\(assists)")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.white.opacity(hasPoints ? 1 : 0.65))
        }
        .frame(width: 70)
    }

    var body: some View {
        if let player {
            NavigationLink(value: player) { content }.buttonStyle(.plain)
        } else {
            content
        }
    }
}

/// 최근 경기 통계로 정리한 팀 성향과 설명.
private struct TacticsPanel: View {
    let tactics: TeamTactics

    private struct Cell: Identifiable {
        let label: String
        let text: String
        var id: String { label }
    }

    private func kpi(_ label: String, _ value: Double?, unit: String = "") -> Cell? {
        value.map { Cell(label: label, text: String(format: "%.1f", $0) + unit) }
    }

    var body: some View {
        let p = tactics.profile
        let cells = [kpi("점유율", p.possession, unit: "%"), kpi("슈팅", p.shots), kpi("유효슈팅", p.shotsOnTarget),
                     kpi("패스 성공", p.passPct, unit: "%"), kpi("득점", p.scored), kpi("실점", p.conceded)].compactMap { $0 }
        FMPanel("주요 전술") {
            VStack(alignment: .leading, spacing: 10) {
                if !p.tags.isEmpty {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 84), spacing: 6)], alignment: .leading, spacing: 6) {
                        ForEach(p.tags, id: \.self) { tag in
                            Text(tag).font(.caption.weight(.bold)).foregroundStyle(Theme.blue)
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(Theme.surfaceHigh, in: Capsule())
                        }
                    }
                }
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 3), spacing: 6) {
                    ForEach(cells) { cell in
                        VStack(spacing: 2) {
                            Text(cell.label).font(.caption2).foregroundStyle(Theme.textSecondary)
                            Text(cell.text).font(.subheadline.weight(.bold)).foregroundStyle(Theme.textPrimary)
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 6)
                        .background(Theme.surfaceHigh, in: RoundedRectangle(cornerRadius: 8))
                    }
                }
                ForEach(Array(tactics.summary.enumerated()), id: \.offset) { _, line in
                    Text("• " + line).font(.footnote).foregroundStyle(Theme.textPrimary)
                }
                Text("최근 \(tactics.opponents.count)경기(\(tactics.opponents.joined(separator: "·"))) ESPN 경기 요약으로 자동 정리한 내용입니다. 감독 전술 해설은 포함하지 않습니다.")
                    .font(.caption2).foregroundStyle(Theme.textSecondary)
            }
        }
    }
}
