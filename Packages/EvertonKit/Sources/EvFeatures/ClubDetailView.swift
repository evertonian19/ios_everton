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
                    TeamSquadSection(clubID: club.id, players: players)
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
        .refreshable {
            await model.reloadRoster(club.id)
            await model.reloadTactics(club.id)
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            ClubLogo(url: club.logoURL, size: 72)
                .padding(8)
                .background(Color.white.opacity(0.10), in: Circle())
                .evGlow(.white, active: true)
            Text(club.name).font(.title3.weight(.bold)).foregroundStyle(.white)
            if let standing {
                HStack(spacing: 6) {
                    StatTile(value: standing.rank, label: "순위", highlight: standing.rank == 1, compact: true)
                    StatTile(value: standing.points, label: "승점", compact: true)
                    StatTile(value: standing.won, label: "승", compact: true)
                    StatTile(value: standing.drawn, label: "무", compact: true)
                    StatTile(value: standing.lost, label: "패", compact: true)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .evHero()
    }
}
