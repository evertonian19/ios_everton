import SwiftUI
import EvCore
import EvDesign

/// 순위표 본문. 리그 탭 안에서 쓰며, 행을 누르면 구단 상세로 이동한다.
struct StandingsContent: View {
    @Environment(AppModel.self) private var model

    private func zoneColor(_ zone: StandingRow.Zone) -> Color {
        switch zone {
        case .champions: return Theme.blue
        case .europa: return Color(hex: 0xF08A24)
        case .conference: return Theme.win
        case .relegation: return Theme.loss
        case .none: return .clear
        }
    }

    var body: some View {
        LoadStateView(state: model.standings, retry: { await model.loadStandings() }) { rows in
                    VStack(spacing: 10) {
                        header
                        VStack(spacing: 0) {
                            ForEach(rows) { row in
                                let mine = row.club.id == EvertonInfo.teamID
                                NavigationLink(value: row.club) {
                                HStack(spacing: 8) {
                                    RoundedRectangle(cornerRadius: 2).fill(zoneColor(row.zone)).frame(width: 3, height: 26)
                                    Text("\(row.rank)").frame(width: 22).font(.footnote.weight(.heavy))
                                    ClubLogo(url: row.club.logoURL, size: 22)
                                    Text(row.club.name).font(.footnote.weight(mine ? .heavy : .regular)).lineLimit(1)
                                    Spacer(minLength: 4)
                                    Group {
                                        Text("\(row.played)").frame(width: 24)
                                        Text("\(row.goalDifference)").frame(width: 30)
                                        Text("\(row.points)").frame(width: 30).fontWeight(.heavy)
                                    }
                                    .font(.footnote)
                                }
                                .foregroundStyle(mine ? Theme.gold : Theme.textPrimary)
                                .padding(.vertical, 7).padding(.horizontal, 8)
                                .background(mine ? Theme.deepBlue.opacity(0.55) : .clear, in: RoundedRectangle(cornerRadius: 10))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .evCard()
                        legend
                    }
                    .padding(16)
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Spacer().frame(width: 3 + 8 + 22 + 8 + 22 + 8)
            Text("팀").frame(maxWidth: .infinity, alignment: .leading)
            Text("경기").frame(width: 24)
            Text("득실").frame(width: 30)
            Text("승점").frame(width: 30)
        }
        .font(.caption2.weight(.heavy))
        .foregroundStyle(Theme.textSecondary)
        .padding(.horizontal, 12)
    }

    private var legend: some View {
        HStack(spacing: 14) {
            ForEach([("챔피언스리그", Theme.blue), ("유로파", Color(hex: 0xF08A24)), ("강등", Theme.loss)], id: \.0) { item in
                HStack(spacing: 5) {
                    Circle().fill(item.1).frame(width: 8, height: 8)
                    Text(item.0).font(.caption2).foregroundStyle(Theme.textSecondary)
                }
            }
        }
    }
}
