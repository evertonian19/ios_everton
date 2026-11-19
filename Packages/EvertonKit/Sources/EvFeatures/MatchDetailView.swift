import SwiftUI
import EvCore
import EvDesign

struct MatchDetailView: View {
    @Environment(AppModel.self) private var model
    let match: Match

    private enum Tab: Hashable { case overview, stats, lineup, events }

    @State private var state: LoadState<MatchDetail> = .idle
    @State private var tab: Tab = .overview
    @State private var homeSide = true

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                header
                FMTabs([(Tab.overview, "개요"), (Tab.stats, "통계"), (Tab.lineup, "라인업"), (Tab.events, "이벤트")], selection: $tab)
                LoadStateView(state: state, retry: { await load() }) { detail in
                    switch tab {
                    case .overview: overview(detail)
                    case .stats: statsPanel(detail)
                    case .lineup: lineupPanel(detail)
                    case .events: eventsPanel(detail)
                    }
                }
                SourceFooter()
            }
            .padding(10)
        }
        .background(Theme.background)
        .navigationTitle(match.opponent().display)
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
        VStack(spacing: 8) {
            Text("\(match.competition) · \(Fmt.day(match.kickoff)) \(Fmt.time(match.kickoff))\(match.venue.map { " · \($0)" } ?? "")")
                .font(.caption).foregroundStyle(Color(hex: 0xC9D3E6))
            HStack {
                club(match.home)
                VStack(spacing: 2) {
                    Text(match.phase == .upcoming ? "VS" : match.scoreText)
                        .font(.system(size: 30, weight: .heavy, design: .rounded)).foregroundStyle(.white)
                    Text(match.statusText).font(.caption2).foregroundStyle(Color(hex: 0x9FB4D8))
                }
                .frame(width: 110)
                club(match.away)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(Theme.heroGradient, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(Color(hex: 0x2B4A86), lineWidth: 1))
    }

    private func club(_ club: Club) -> some View {
        VStack(spacing: 6) {
            ClubLogo(url: club.logoURL, size: 52)
            Text(club.display).font(.footnote.weight(.bold)).foregroundStyle(.white).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: 탭 내용

    @ViewBuilder
    private func overview(_ detail: MatchDetail) -> some View {
        if !detail.stats.isEmpty {
            FMPanel("요약") {
                VStack(spacing: 10) { ForEach(detail.stats.prefix(4)) { StatCompareRow($0) } }
            }
        }
        eventsPanel(detail)
    }

    @ViewBuilder
    private func statsPanel(_ detail: MatchDetail) -> some View {
        if detail.stats.isEmpty {
            FMPanel("경기 통계") { Text("통계가 아직 없어요.").font(.footnote).foregroundStyle(Theme.textSecondary) }
        } else {
            FMPanel("경기 통계") {
                VStack(spacing: 12) { ForEach(detail.stats) { StatCompareRow($0) } }
            }
        }
    }

    @ViewBuilder
    private func eventsPanel(_ detail: MatchDetail) -> some View {
        let events = detail.events.filter(\.isKey)
        FMPanel("주요 장면") {
            if events.isEmpty {
                Text("주요 장면이 없어요.").font(.footnote).foregroundStyle(Theme.textSecondary)
            } else {
                EventTimeline(events: events, match: match)
            }
        }
    }

    @ViewBuilder
    private func lineupPanel(_ detail: MatchDetail) -> some View {
        let lineup = detail.lineups.first(where: { ($0.club.id == match.home.id) == homeSide }) ?? detail.lineups.first
        if let lineup {
            FMPanel("\(lineup.club.display) \(lineup.formation ?? "")") {
                VStack(spacing: 10) {
                    FMTabs([(true, "홈"), (false, "원정")], selection: $homeSide)
                    PitchLineupView(lineup: lineup)
                    if !lineup.substitutes.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("교체 명단").font(.caption.weight(.bold)).foregroundStyle(Theme.textSecondary)
                            Text(lineup.substitutes.map { "\($0.number.map { "\($0) " } ?? "")\($0.shortName)" }.joined(separator: " · "))
                                .font(.caption).foregroundStyle(Theme.textPrimary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        } else {
            FMPanel("라인업") { Text("라인업이 아직 없어요.").font(.footnote).foregroundStyle(Theme.textSecondary) }
        }
    }
}
