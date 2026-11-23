import SwiftUI
import EvCore
import EvDesign

/// 리그 탭: 순위표와 20개 구단 목록. 구단 → 선수 → 선수 프로필까지 이어서 볼 수 있다.
struct LeagueView: View {
    @Environment(AppModel.self) private var model

    private enum Section: Hashable { case table, clubs }
    @State private var section: Section = .table

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {
                    FMTabs([(Section.table, "순위"), (Section.clubs, "구단")], selection: $section)
                    switch section {
                    case .table: StandingsContent()
                    case .clubs: ClubsGrid()
                    }
                    SourceFooter()
                }
                .padding(10)
            }
            .background(Theme.background)
            .evBrandBars()
            .navigationTitle("Premier League")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable { await model.loadStandings(); await model.loadClubs() }
            .navigationDestination(for: Club.self) { ClubDetailView(club: $0) }
            .navigationDestination(for: Player.self) { PlayerDetailView(player: $0) }
        }
    }
}

struct ClubsGrid: View {
    @Environment(AppModel.self) private var model

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)

    var body: some View {
        LoadStateView(state: model.clubs, retry: { await model.loadClubs() }) { clubs in
            let sorted = clubs.sorted { a, b in
                if EvertonInfo.isEverton(a.id) { return true }
                if EvertonInfo.isEverton(b.id) { return false }
                return a.club.name < b.club.name
            }
            FMPanel("프리미어리그 \(clubs.count)개 구단") {
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(sorted) { info in
                        NavigationLink(value: info.club) {
                            VStack(spacing: 4) {
                                ClubLogo(url: info.club.logoURL, size: 38)
                                Text(info.club.display).font(.system(size: 10.5, weight: .semibold))
                                    .foregroundStyle(Theme.textPrimary).lineLimit(1).minimumScaleFactor(0.7)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(EvertonInfo.isEverton(info.id) ? Theme.blue.opacity(0.15) : Color.clear,
                                        in: RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}
