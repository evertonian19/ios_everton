import SwiftUI
import EvCore
import EvDesign

/// 구단 정보와 소속 선수. 선수는 이 화면을 열 때에만 불러온다(무료 API 호출 한도 절약).
struct ClubDetailView: View {
    @Environment(AppModel.self) private var model
    let club: Club

    @State private var squad: LoadState<[Player]> = .idle

    private let columns = [GridItem(.adaptive(minimum: 104), spacing: 10)]

    private var info: ClubInfo? { model.clubs.value?.first { $0.id == club.id } }
    private var standing: StandingRow? { model.standings.value?.first { $0.club.id == club.id } }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                header
                if let standing { standingCard(standing) }
                LoadStateView(state: squad, retry: { await loadSquad() }) { players in
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
                }
            }
            .padding(16)
        }
        .background(Theme.background)
        .navigationTitle(club.name)
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadSquad() }
        .refreshable { await loadSquad() }
    }

    private func loadSquad() async {
        if squad.value == nil { squad = .loading }
        do { squad = .loaded(try await model.services.football.squad(of: club.id)) }
        catch { if squad.value == nil { squad = .failed(error.localizedDescription) } }
    }

    private var header: some View {
        VStack(spacing: 12) {
            ClubLogo(url: club.logoURL, size: 96).shadow(color: Theme.blue.opacity(0.8), radius: 20)
            Text(club.name).font(.title2.weight(.heavy)).foregroundStyle(Theme.textPrimary)
            HStack(spacing: 10) {
                fact("창단", info?.founded.map(String.init) ?? "-")
                fact("경기장", info?.venueName ?? "-")
                fact("수용", Fmt.capacity(info?.capacity))
            }
            if let city = info?.city {
                Text(city).font(.caption).foregroundStyle(Theme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(18)
        .background(Theme.heroGradient, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func fact(_ label: String, _ value: String) -> some View {
        VStack(spacing: 3) {
            Text(value).font(.footnote.weight(.bold)).foregroundStyle(Theme.textPrimary)
                .lineLimit(2).multilineTextAlignment(.center).minimumScaleFactor(0.8)
            Text(label).font(.caption2).foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func standingCard(_ row: StandingRow) -> some View {
        HStack {
            VStack(spacing: 0) {
                Text("\(row.rank)").font(.system(size: 30, weight: .black, design: .rounded)).foregroundStyle(Theme.gold)
                Text("순위").font(.caption2).foregroundStyle(Theme.textSecondary)
            }
            .frame(width: 60)
            VStack(alignment: .leading, spacing: 4) {
                Text("\(row.played)경기 \(row.won)승 \(row.drawn)무 \(row.lost)패")
                    .font(.footnote.weight(.semibold)).foregroundStyle(Theme.textPrimary)
                Text("득점 \(row.goalsFor) · 실점 \(row.goalsAgainst) · 승점 \(row.points)")
                    .font(.caption).foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            HStack(spacing: 4) {
                ForEach(Array(row.form.suffix(5).enumerated()), id: \.offset) { _, letter in
                    FormBadge(letter == "W" ? .win : (letter == "D" ? .draw : .loss))
                }
            }
        }
        .evCard()
    }
}
