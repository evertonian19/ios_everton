import SwiftUI
import EvCore
import EvDesign

struct SquadView: View {
    @Environment(AppModel.self) private var model

    private let columns = [GridItem(.adaptive(minimum: 104), spacing: 10)]

    var body: some View {
        NavigationStack {
            ScrollView {
                LoadStateView(state: model.squad, retry: { await model.loadSquad() }) { players in
                    VStack(spacing: 20) {
                        ForEach(Position.allCases, id: \.self) { position in
                            let group = players.filter { $0.position == position }
                            if !group.isEmpty {
                                VStack(spacing: 8) {
                                    SectionTitle(position.title, trailing: "\(group.count)명")
                                    LazyVGrid(columns: columns, spacing: 10) {
                                        ForEach(group) { player in
                                            NavigationLink(value: player) { PlayerCard(player) }.buttonStyle(.plain)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .background(Theme.background)
            .navigationTitle("스쿼드")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable { await model.loadSquad() }
            .navigationDestination(for: Player.self) { PlayerDetailView(player: $0) }
        }
    }
}
