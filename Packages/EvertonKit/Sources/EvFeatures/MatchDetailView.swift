import SwiftUI
import EvCore
import EvDesign

struct MatchDetailView: View {
    @Environment(AppModel.self) private var model
    let match: Match

    private enum Tab: String, CaseIterable, Identifiable {
        case stats = "통계", lineup = "라인업", ratings = "평점"
        var id: String { rawValue }
    }

    @State private var state: LoadState<MatchDetail> = .idle
    @State private var tab: Tab = .stats

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header
                Picker("보기", selection: $tab) {
                    ForEach(Tab.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)

                LoadStateView(state: state, retry: { await load() }) { detail in
                    switch tab {
                    case .stats: statsSection(detail)
                    case .lineup: lineupSection(detail)
                    case .ratings: ratingsSection(detail)
                    }
                }
            }
            .padding(16)
        }
        .background(Theme.background)
        .navigationTitle("\(match.opponent().name)")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
        .refreshable { await load() }
    }

    private func load() async {
        if state.value == nil { state = .loading }
        do { state = .loaded(try await model.services.football.detail(of: match)) }
        catch { if state.value == nil { state = .failed(error.localizedDescription) } }
    }

    // MARK: 헤더

    private var header: some View {
        VStack(spacing: 10) {
            HStack {
                VStack(spacing: 6) {
                    ClubLogo(url: match.home.logoURL, size: 56)
                    Text(match.home.name).font(.footnote.weight(.semibold)).multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                VStack(spacing: 4) {
                    Text(match.phase == .upcoming ? Fmt.time(match.kickoff) : match.scoreText)
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                    Text(match.phase == .live ? "LIVE \(match.elapsed ?? 0)'" : match.statusText)
                        .font(.caption2.weight(.heavy))
                        .foregroundStyle(match.phase == .live ? Theme.loss : Theme.textSecondary)
                }
                .frame(width: 118)
                VStack(spacing: 6) {
                    ClubLogo(url: match.away.logoURL, size: 56)
                    Text(match.away.name).font(.footnote.weight(.semibold)).multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
            }
            .foregroundStyle(Theme.textPrimary)
            Text("\(Fmt.day(match.kickoff)) · \(match.round)\(match.venue.map { " · \($0)" } ?? "")")
                .font(.caption).foregroundStyle(Theme.textSecondary).multilineTextAlignment(.center)
        }
        .padding(16)
        .background(Theme.heroGradient, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    // MARK: 탭 내용

    @ViewBuilder
    private func statsSection(_ detail: MatchDetail) -> some View {
        if detail.stats.isEmpty {
            emptyNote("아직 경기 통계가 없습니다.")
        } else {
            VStack(spacing: 14) {
                ForEach(detail.stats) { StatCompareRow($0) }
            }
            .evCard()
        }
    }

    @ViewBuilder
    private func lineupSection(_ detail: MatchDetail) -> some View {
        if let lineup = evertonLineup(detail) {
            VStack(spacing: 14) {
                HStack {
                    Text(lineup.club.name).font(.headline)
                    Spacer()
                    if let formation = lineup.formation {
                        Text(formation).font(.subheadline.weight(.heavy)).foregroundStyle(Theme.gold)
                    }
                }
                .foregroundStyle(Theme.textPrimary)
                PitchLineupView(lineup: lineup)
                if !lineup.substitutes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        SectionTitle("교체 명단")
                        ForEach(lineup.substitutes) { player in
                            PlayerLine(player: player)
                        }
                    }
                    .evCard()
                }
            }
        } else {
            emptyNote("라인업은 경기 직전에 공개됩니다.")
        }
    }

    @ViewBuilder
    private func ratingsSection(_ detail: MatchDetail) -> some View {
        if let lineup = evertonLineup(detail) {
            let rated = (lineup.starters + lineup.substitutes)
                .filter { $0.rating != nil }
                .sorted { ($0.rating ?? 0) > ($1.rating ?? 0) }
            if rated.isEmpty {
                emptyNote("평점은 경기 후에 집계됩니다.")
            } else {
                VStack(spacing: 10) {
                    ForEach(Array(rated.enumerated()), id: \.element.id) { index, player in
                        HStack(spacing: 10) {
                            Text("\(index + 1)").font(.caption.weight(.heavy)).foregroundStyle(Theme.textSecondary).frame(width: 18)
                            PlayerPhoto(url: player.photoURL, name: player.name, size: 36)
                            Text(player.name).font(.subheadline).foregroundStyle(Theme.textPrimary)
                            if index == 0 {
                                Image(systemName: "crown.fill").foregroundStyle(Theme.gold).font(.caption)
                            }
                            Spacer()
                            RatingRing(player.rating, size: 38)
                        }
                    }
                }
                .evCard()
            }
        } else {
            emptyNote("평점은 경기 후에 집계됩니다.")
        }
    }

    private func evertonLineup(_ detail: MatchDetail) -> TeamLineup? {
        detail.lineups.first(where: { $0.club.id == EvertonInfo.teamID }) ?? detail.lineups.first
    }

    private func emptyNote(_ text: String) -> some View {
        Text(text).font(.footnote).foregroundStyle(Theme.textSecondary)
            .frame(maxWidth: .infinity, minHeight: 120)
    }
}

private struct PlayerLine: View {
    let player: LineupPlayer

    var body: some View {
        HStack(spacing: 10) {
            Text(player.number.map(String.init) ?? "-")
                .font(.caption.weight(.heavy)).foregroundStyle(Theme.gold).frame(width: 24)
            Text(player.name).font(.subheadline).foregroundStyle(Theme.textPrimary)
            Spacer()
            if player.rating != nil { RatingRing(player.rating, size: 30) }
        }
    }
}
