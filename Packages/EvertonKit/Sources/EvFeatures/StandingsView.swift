import SwiftUI
import EvCore
import EvDesign

/// 순위표 본문. 행을 누르면 구단 상세로 이동한다. 왼쪽 막대 색이 챔피언스리그/유로파/강등 구간.
struct StandingsContent: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        LoadStateView(state: model.standings, retry: { await model.loadStandings() }) { rows in
            FMPanel {
                VStack(spacing: 0) {
                    header
                    Divider().overlay(Theme.line)
                    ForEach(rows) { row in
                        NavigationLink(value: row.club) { line(row) }.buttonStyle(.plain)
                        Divider().overlay(Theme.line.opacity(0.4))
                    }
                    legend.padding(.top, 8)
                }
            }
        }
    }

    private var header: some View {
        HStack(spacing: 4) {
            Text("#").frame(width: 28)
            Text("구단").frame(maxWidth: .infinity, alignment: .leading)
            Group { Text("경기"); Text("승"); Text("무"); Text("패") }.frame(width: 26)
            Text("득실").frame(width: 32)
            Text("승점").frame(width: 32)
        }
        .font(.caption2.weight(.bold)).foregroundStyle(Theme.textSecondary)
        .padding(.bottom, 5)
    }

    private func line(_ row: StandingRow) -> some View {
        let mine = EvertonInfo.isEverton(row.club.id)
        return HStack(spacing: 4) {
            Text("\(row.rank)").font(.caption.weight(.bold)).foregroundStyle(Theme.textSecondary)
                .frame(width: 28)
                .overlay(alignment: .leading) { Rectangle().fill(Theme.zoneColor(row.zone)).frame(width: 3) }
            HStack(spacing: 6) {
                ClubLogo(url: row.club.logoURL, size: 18)
                Text(row.club.display).font(.footnote.weight(mine ? .heavy : .semibold)).foregroundStyle(Theme.textPrimary).lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Group {
                Text("\(row.played)"); Text("\(row.won)"); Text("\(row.drawn)"); Text("\(row.lost)")
            }
            .frame(width: 26).font(.caption)
            Text(row.goalDifference > 0 ? "+\(row.goalDifference)" : "\(row.goalDifference)").font(.caption).frame(width: 32)
            Text("\(row.points)").font(.footnote.weight(.heavy)).frame(width: 32)
        }
        .foregroundStyle(Theme.textPrimary)
        .padding(.vertical, 7)
        .background(mine ? Theme.blue.opacity(0.13) : Color.clear)
        .contentShape(Rectangle())
    }

    private var legend: some View {
        HStack(spacing: 10) {
            ForEach([(StandingRow.Zone.champions, "챔피언스리그"), (.europa, "유로파"), (.relegation, "강등")], id: \.1) { item in
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 2).fill(Theme.zoneColor(item.0)).frame(width: 8, height: 8)
                    Text(item.1).font(.caption2).foregroundStyle(Theme.textSecondary)
                }
            }
            Spacer()
        }
    }
}
