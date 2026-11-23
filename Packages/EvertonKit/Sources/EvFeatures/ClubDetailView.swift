import SwiftUI
import EvCore
import EvDesign

/// 구단 정보와 소속 선수. 선수는 이 화면을 열 때에만 불러온다.
struct ClubDetailView: View {
    @Environment(AppModel.self) private var model
    let club: Club

    private var standing: StandingRow? { model.standings.value?.first { $0.club.id == club.id } }
    private var roster: LoadState<[Player]> { model.rosters[club.id] ?? .idle }

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                header
                LoadStateView(state: roster, retry: { await model.loadRoster(club.id) }) { players in
                    FMPanel("스쿼드 · \(players.count)명") { RosterTable(players: players) }
                }
                SourceFooter()
            }
            .padding(10)
        }
        .background(Theme.background)
        .evBrandBars()
        .navigationTitle(club.display)
        .navigationBarTitleDisplayMode(.inline)
        .task { await model.loadRoster(club.id) }
        .refreshable { await model.reloadRoster(club.id) }
    }

    private var header: some View {
        VStack(spacing: 8) {
            ClubLogo(url: club.logoURL, size: 64)
            Text(club.name).font(.title3.weight(.bold)).foregroundStyle(.white)
            if let standing {
                Text("\(standing.rank)위 · 승점 \(standing.points) · \(standing.won)승 \(standing.drawn)무 \(standing.lost)패")
                    .font(.footnote).foregroundStyle(Theme.onBrand2)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .evHero()
    }
}
