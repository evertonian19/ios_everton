import SwiftUI
import EvCore
import EvDesign

/// 로딩·실패·완료 상태에 맞춰 화면을 바꿔 주는 래퍼.
struct LoadStateView<Value, Content: View>: View {
    let state: LoadState<Value>
    let retry: () async -> Void
    @ViewBuilder let content: (Value) -> Content

    var body: some View {
        switch state {
        case .idle, .loading:
            ProgressView().tint(Theme.blue).frame(maxWidth: .infinity, minHeight: 160)
        case .failed(let message):
            VStack(spacing: 10) {
                Image(systemName: "wifi.exclamationmark").font(.title2).foregroundStyle(Theme.loss)
                Text(message).font(.footnote).multilineTextAlignment(.center).foregroundStyle(Theme.textSecondary)
                Button("다시 시도") { Task { await retry() } }
                    .buttonStyle(.borderedProminent).tint(Theme.blue)
            }
            .frame(maxWidth: .infinity, minHeight: 160)
        case .loaded(let value):
            content(value)
        }
    }
}

/// 표 안에서 한 줄짜리 경기 행 (일정, 홈의 최근 경기에서 공통 사용).
struct MatchRow: View {
    let match: Match

    private var resultColor: Color {
        switch match.result() {
        case .win: return Theme.win
        case .loss: return Theme.loss
        case .draw: return Theme.draw
        case nil: return Theme.line
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            Text(Fmt.shortDay(match.kickoff)).font(.caption).foregroundStyle(Theme.textSecondary)
                .frame(width: 38, alignment: .leading)
            Text(match.isHome() ? "H" : "A")
                .font(.system(size: 9, weight: .black))
                .frame(width: 16, height: 16)
                .background(match.isHome() ? Color(hex: 0x1D3F73) : Theme.surfaceHigh, in: RoundedRectangle(cornerRadius: 3))
                .foregroundStyle(match.isHome() ? Color(hex: 0xCFE3FF) : Theme.textSecondary)
            ClubLogo(url: match.opponent().logoURL, size: 22)
            Text(match.opponent().display).font(.subheadline.weight(.semibold)).foregroundStyle(Theme.textPrimary).lineLimit(1)
            Spacer()
            if match.phase == .finished || match.phase == .live {
                Text(match.scoreText.replacingOccurrences(of: " : ", with: "-"))
                    .font(.caption.weight(.heavy)).foregroundStyle(.white)
                    .padding(.horizontal, 7).padding(.vertical, 3)
                    .background(match.phase == .live ? Theme.gold : resultColor, in: RoundedRectangle(cornerRadius: 4))
            } else {
                Text(Fmt.time(match.kickoff)).font(.caption.weight(.bold)).foregroundStyle(Theme.blue)
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}

/// FM 식 선수 표: 번호 · 포지션 · 이름 · 나이 · 출전 · 골 · 도움. 머리글을 눌러 정렬한다.
struct RosterTable: View {
    let players: [Player]

    private enum Sort: String { case position, age, apps, goals, assists }
    @State private var sort: Sort = .position

    private var sorted: [Player] {
        switch sort {
        case .position: return players
        case .age: return players.sorted { ($0.age ?? 0) < ($1.age ?? 0) }
        case .apps: return players.sorted { ($0.stats?.appearances ?? 0) > ($1.stats?.appearances ?? 0) }
        case .goals: return players.sorted { ($0.stats?.goals ?? 0) > ($1.stats?.goals ?? 0) }
        case .assists: return players.sorted { ($0.stats?.assists ?? 0) > ($1.stats?.assists ?? 0) }
        }
    }

    private func header(_ title: String, _ key: Sort, width: CGFloat) -> some View {
        Button { sort = key } label: {
            Text(title).font(.caption2.weight(.bold))
                .foregroundStyle(sort == key ? Theme.blue : Theme.textSecondary)
                .frame(width: width)
        }
        .buttonStyle(.plain)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Button { sort = .position } label: {
                    Text("선수").font(.caption2.weight(.bold)).foregroundStyle(sort == .position ? Theme.blue : Theme.textSecondary)
                }
                .buttonStyle(.plain)
                Spacer()
                header("나이", .age, width: 30)
                header("출전", .apps, width: 30)
                header("골", .goals, width: 26)
                header("도움", .assists, width: 30)
            }
            .padding(.bottom, 6)
            Divider().overlay(Theme.line)
            ForEach(sorted) { player in
                NavigationLink(value: player) { row(player) }.buttonStyle(.plain)
                Divider().overlay(Theme.line.opacity(0.5))
            }
        }
    }

    private func row(_ player: Player) -> some View {
        let stats = player.stats
        return HStack(spacing: 6) {
            Text(player.number.map(String.init) ?? "-").font(.caption.weight(.bold)).foregroundStyle(Theme.textSecondary)
                .frame(width: 22, alignment: .trailing)
            PlayerPhoto(url: player.photoURL, name: player.name, size: 22)
                .clipShape(Circle())
            PositionTag(player.position)
            FlagImage(player.flagURL)
            Text(player.shortName).font(.subheadline.weight(.semibold)).foregroundStyle(Theme.textPrimary)
                .lineLimit(1).minimumScaleFactor(0.75).layoutPriority(1)
            Spacer(minLength: 2)
            cell(player.age.map(String.init), width: 30)
            cell(stats.map { String($0.appearances) }, width: 30)
            cell(stats.map { String($0.goals) }, width: 26, highlight: (stats?.goals ?? 0) > 0)
            cell(stats.map { String($0.assists) }, width: 30, highlight: (stats?.assists ?? 0) > 0)
        }
        .padding(.vertical, 7)
        .contentShape(Rectangle())
    }

    private func cell(_ text: String?, width: CGFloat, highlight: Bool = false) -> some View {
        Text(text ?? "-").font(.caption.weight(highlight ? .heavy : .regular))
            .foregroundStyle(highlight ? Theme.textPrimary : Theme.textSecondary)
            .frame(width: width)
    }
}

/// 화면 하단의 데이터 출처 표시.
struct SourceFooter: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        Text("데이터 출처: \(model.services.sourceName)")
            .font(.caption2).foregroundStyle(Theme.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.top, 4)
    }
}
