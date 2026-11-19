import SwiftUI
import EvCore
import EvDesign

/// 리그 탭: 순위표와 20개 구단 목록. 구단 → 선수까지 이어서 볼 수 있다.
struct LeagueView: View {
    @Environment(AppModel.self) private var model

    private enum Section: String, CaseIterable, Identifiable {
        case table = "순위", clubs = "구단"
        var id: String { rawValue }
    }

    @State private var section: Section = .table

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 8) {
                    Picker("보기", selection: $section) {
                        ForEach(Section.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16).padding(.top, 8)

                    switch section {
                    case .table: StandingsContent()
                    case .clubs: ClubsGrid()
                    }
                }
            }
            .background(Theme.background)
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

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        LoadStateView(state: model.clubs, retry: { await model.loadClubs() }) { clubs in
            // Everton 을 맨 앞에 고정한다.
            let sorted = clubs.sorted { a, b in
                if a.id == EvertonInfo.teamID { return true }
                if b.id == EvertonInfo.teamID { return false }
                return a.club.name < b.club.name
            }
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(sorted) { info in
                    NavigationLink(value: info.club) { ClubCard(info: info) }.buttonStyle(.plain)
                }
            }
            .padding(16)
        }
    }
}

private struct ClubCard: View {
    let info: ClubInfo

    var body: some View {
        let mine = info.id == EvertonInfo.teamID
        VStack(spacing: 8) {
            ClubLogo(url: info.club.logoURL, size: 64)
                .shadow(color: (mine ? Theme.gold : Theme.blue).opacity(0.5), radius: 12)
            Text(info.club.name).font(.subheadline.weight(.bold)).foregroundStyle(Theme.textPrimary)
                .lineLimit(1).minimumScaleFactor(0.8)
            Text(info.venueName ?? "").font(.caption2).foregroundStyle(Theme.textSecondary).lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14).padding(.horizontal, 8)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
            .stroke(mine ? Theme.gold : Theme.line.opacity(0.6), lineWidth: mine ? 2 : 1))
    }
}
