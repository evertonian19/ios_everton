import SwiftUI
import EvCore
import EvDesign

struct SquadView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {
                    LoadStateView(state: model.squad, retry: { await model.loadSquad() }) { players in
                        TeamSquadSection(clubID: model.services.football.homeTeamID, players: players)
                    }
                    SourceFooter()
                }
                .padding(10)
            }
            .background(Theme.background)
            .evBrandBars()
            .navigationTitle("스쿼드")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                await model.loadSquad()
                await model.reloadTactics(model.services.football.homeTeamID)
            }
            .navigationDestination(for: Player.self) { PlayerDetailView(player: $0) }
        }
    }
}
