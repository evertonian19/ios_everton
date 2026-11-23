import SwiftUI
import EvCore
import EvDesign

/// 클럽 개요: 다음 경기, 리그 순위, 최근 경기, 공격 포인트 TOP, 뉴스.
struct HomeView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.openURL) private var openURL
    @State private var showCheck = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {
                    LoadStateView(state: model.matches, retry: { await model.loadMatches() }) { matches in
                        VStack(spacing: 10) {
                            if let next = matches.nextMatch() {
                                NavigationLink(value: next) { NextMatchPanel(match: next) }.buttonStyle(.plain)
                            }
                            standingPanel(matches)
                            recentPanel(matches)
                        }
                    }
                    topPanel
                    newsPanel
                    SourceFooter()
                }
                .padding(10)
            }
            .background(Theme.background)
            .evBrandBars()
            .navigationTitle("Everton")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable { await model.loadAll() }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showCheck = true } label: { Image(systemName: "checkmark.shield") }
                        .accessibilityLabel("데이터 점검")
                }
            }
            .sheet(isPresented: $showCheck) { DataCheckView() }
            .navigationDestination(for: Match.self) { MatchDetailView(match: $0) }
            .navigationDestination(for: Player.self) { PlayerDetailView(player: $0) }
        }
    }

    @ViewBuilder
    private func standingPanel(_ matches: [Match]) -> some View {
        if let row = model.standings.value?.first(where: { EvertonInfo.isEverton($0.club.id) }) {
            FMPanel("리그 순위") {
                VStack(spacing: 10) {
                    HStack {
                        stat("순위", "\(row.rank)위")
                        stat("승점", "\(row.points)")
                        stat("승-무-패", "\(row.won)-\(row.drawn)-\(row.lost)")
                        stat("득실", row.goalDifference > 0 ? "+\(row.goalDifference)" : "\(row.goalDifference)")
                    }
                    Divider().overlay(Theme.line)
                    HStack(spacing: 4) {
                        ForEach(Array(matches.recentResults(5).enumerated()), id: \.offset) { _, match in
                            FormBadge(match.result())
                        }
                        Spacer()
                        Text("최근 5경기").font(.caption2).foregroundStyle(Theme.textSecondary)
                    }
                }
            }
        }
    }

    private func stat(_ label: String, _ value: String) -> some View {
        VStack(spacing: 3) {
            Text(label).font(.caption2).foregroundStyle(Theme.textSecondary)
            Text(value).font(.headline.weight(.heavy)).foregroundStyle(Theme.textPrimary)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func recentPanel(_ matches: [Match]) -> some View {
        let recent = matches.recentResults(5).reversed()
        if !recent.isEmpty {
            FMPanel("최근 경기") {
                VStack(spacing: 0) {
                    ForEach(Array(recent)) { match in
                        NavigationLink(value: match) { MatchRow(match: match) }.buttonStyle(.plain)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var topPanel: some View {
        if let players = model.squad.value {
            let top = PlayerMetrics.topContributors(players, limit: 5)
            if !top.isEmpty {
                FMPanel("공격 포인트 TOP") {
                    VStack(spacing: 0) {
                        ForEach(top) { player in
                            NavigationLink(value: player) {
                                HStack(spacing: 8) {
                                    PositionTag(player.position)
                                    Text(player.shortName).font(.subheadline.weight(.semibold)).foregroundStyle(Theme.textPrimary)
                                    Spacer()
                                    Text("\(player.stats?.goals ?? 0)골 \(player.stats?.assists ?? 0)도움")
                                        .font(.caption).foregroundStyle(Theme.textSecondary)
                                    Text("\(player.stats?.contribution ?? 0)").font(.headline.weight(.heavy))
                                        .foregroundStyle(Theme.attributeColor(Double(player.stats?.contribution ?? 0) / 8))
                                        .frame(width: 26)
                                }
                                .padding(.vertical, 6)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var newsPanel: some View {
        if let items = model.news.value, !items.isEmpty {
            FMPanel("최근 뉴스") {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(items.prefix(3)) { item in
                        Button { if let url = item.link { openURL(url) } } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title).font(.footnote.weight(.semibold)).foregroundStyle(Theme.textPrimary)
                                    .multilineTextAlignment(.leading)
                                if let date = item.date { Text(Fmt.day(date)).font(.caption2).foregroundStyle(Theme.textSecondary) }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

private struct NextMatchPanel: View {
    let match: Match

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("다음 경기 · \(match.competition)").font(.caption.weight(.heavy)).foregroundStyle(Theme.onBrand2)
                Spacer()
                Text(match.isHome() ? "홈" : "원정").font(.caption2.weight(.heavy))
                    .padding(.horizontal, 7).padding(.vertical, 2)
                    .background(match.isHome() ? Theme.gold : Theme.surfaceHigh, in: RoundedRectangle(cornerRadius: 5))
                    .foregroundStyle(match.isHome() ? Color.black : Theme.textPrimary)
            }
            HStack {
                team(match.home)
                VStack(spacing: 4) {
                    if match.phase == .live {
                        Text(match.scoreText).font(.system(size: 28, weight: .heavy, design: .rounded))
                        Text("LIVE").font(.caption.weight(.heavy)).foregroundStyle(Color(hex: 0xFF8A8D))
                    } else {
                        Text("VS").font(.title3.weight(.black)).foregroundStyle(Theme.onBrand2)
                        TimelineView(.periodic(from: .now, by: 1)) { context in
                            Text(Fmt.countdown(to: match.kickoff, from: context.date) ?? "곧 시작")
                                .font(.system(.callout, design: .monospaced).weight(.bold))
                                .foregroundStyle(Theme.gold)
                                .contentTransition(.numericText())
                        }
                    }
                }
                .frame(width: 110)
                team(match.away)
            }
            Text("\(Fmt.day(match.kickoff)) \(Fmt.time(match.kickoff))\(match.venue.map { " · \($0)" } ?? "")")
                .font(.caption).foregroundStyle(Theme.onBrand2)
        }
        .padding(12)
        .evHero()
        .foregroundStyle(Theme.onBrand)
    }

    private func team(_ club: Club) -> some View {
        VStack(spacing: 6) {
            ClubLogo(url: club.logoURL, size: 52)
            Text(club.display).font(.footnote.weight(.bold)).multilineTextAlignment(.center).lineLimit(2)
        }
        .frame(maxWidth: .infinity)
    }
}
