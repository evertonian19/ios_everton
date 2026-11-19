import SwiftUI
import EvCore
import EvDesign

struct HomeView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if model.services.isSample { SampleBanner() }

                    LoadStateView(state: model.matches, retry: { await model.loadMatches() }) { matches in
                        VStack(spacing: 20) {
                            if let next = matches.nextMatch() {
                                NavigationLink(value: next) { NextMatchHero(match: next) }.buttonStyle(.plain)
                            }
                            FormStrip(matches: matches)
                            if let last = matches.recentResults(1).last {
                                VStack(spacing: 8) {
                                    SectionTitle("지난 경기")
                                    NavigationLink(value: last) { LastMatchCard(match: last) }.buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    if let players = model.squad.value {
                        let top = PlayerMetrics.topRated(players)
                        if !top.isEmpty {
                            VStack(spacing: 8) {
                                SectionTitle("이번 시즌 평점 TOP")
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(top) { player in
                                            NavigationLink(value: player) { TopPlayerTile(player: player) }.buttonStyle(.plain)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    if let matches = model.matches.value {
                        let upcoming = matches.filter { $0.phase == .upcoming }.prefix(4)
                        if !upcoming.isEmpty {
                            VStack(spacing: 8) {
                                SectionTitle("다음 일정")
                                VStack(spacing: 0) {
                                    ForEach(Array(upcoming)) { match in
                                        NavigationLink(value: match) { MatchRow(match: match) }.buttonStyle(.plain)
                                        if match.id != upcoming.last?.id { Divider().overlay(Theme.line.opacity(0.5)) }
                                    }
                                }
                                .evCard()
                            }
                        }
                    }
                }
                .padding(16)
            }
            .background(Theme.background)
            .navigationTitle("EVERTON")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable { await model.loadAll() }
            .navigationDestination(for: Match.self) { MatchDetailView(match: $0) }
            .navigationDestination(for: Player.self) { PlayerDetailView(player: $0) }
        }
    }
}

private struct NextMatchHero: View {
    let match: Match

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Text(match.competition.uppercased()).font(.caption2.weight(.heavy)).tracking(1.2)
                Spacer()
                Text(match.isHome() ? "HOME" : "AWAY")
                    .font(.caption2.weight(.heavy))
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(match.isHome() ? Theme.gold : Theme.line, in: Capsule())
                    .foregroundStyle(match.isHome() ? .black : Theme.textPrimary)
            }
            .foregroundStyle(Theme.textSecondary)

            HStack {
                VStack(spacing: 6) {
                    ClubLogo(url: match.home.logoURL, size: 64)
                    Text(match.home.name).font(.footnote.weight(.semibold)).multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                VStack(spacing: 4) {
                    if match.phase == .live {
                        Text(match.scoreText).font(.system(size: 34, weight: .heavy, design: .rounded))
                        Text("LIVE \(match.elapsed.map { "\($0)'" } ?? "")")
                            .font(.caption.weight(.heavy)).foregroundStyle(Theme.loss)
                    } else {
                        Text("VS").font(.system(size: 26, weight: .black, design: .rounded)).foregroundStyle(Theme.gold)
                        TimelineView(.periodic(from: .now, by: 1)) { context in
                            Text(Fmt.countdown(to: match.kickoff, from: context.date) ?? "곧 시작")
                                .font(.system(.footnote, design: .monospaced).weight(.semibold))
                                .foregroundStyle(Theme.textPrimary)
                        }
                    }
                }
                .frame(width: 112)
                VStack(spacing: 6) {
                    ClubLogo(url: match.away.logoURL, size: 64)
                    Text(match.away.name).font(.footnote.weight(.semibold)).multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
            }
            .foregroundStyle(Theme.textPrimary)

            Text("\(Fmt.day(match.kickoff)) \(Fmt.time(match.kickoff))\(match.venue.map { " · \($0)" } ?? "")")
                .font(.caption).foregroundStyle(Theme.textSecondary)
        }
        .padding(16)
        .background(Theme.heroGradient, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Theme.blue.opacity(0.45), lineWidth: 1))
    }
}

private struct FormStrip: View {
    let matches: [Match]

    var body: some View {
        let recent = matches.recentResults(5)
        if !recent.isEmpty {
            VStack(spacing: 8) {
                SectionTitle("최근 폼")
                HStack(spacing: 8) {
                    ForEach(recent) { match in
                        VStack(spacing: 4) {
                            FormBadge(match.result())
                            ClubLogo(url: match.opponent().logoURL, size: 22)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .evCard()
            }
        }
    }
}

private struct LastMatchCard: View {
    let match: Match

    var body: some View {
        HStack {
            ClubLogo(url: match.home.logoURL, size: 38)
            Text(match.home.name).font(.footnote.weight(.semibold)).lineLimit(1)
            Spacer()
            Text(match.scoreText).font(.system(size: 22, weight: .heavy, design: .rounded))
            Spacer()
            Text(match.away.name).font(.footnote.weight(.semibold)).lineLimit(1)
            ClubLogo(url: match.away.logoURL, size: 38)
        }
        .foregroundStyle(Theme.textPrimary)
        .evCard()
    }
}

private struct TopPlayerTile: View {
    let player: Player

    var body: some View {
        VStack(spacing: 6) {
            ZStack(alignment: .bottomTrailing) {
                PlayerPhoto(url: player.photoURL, name: player.name, size: 70)
                RatingRing(player.stats?.rating, size: 30)
                    .background(Theme.background, in: Circle())
            }
            Text(player.shortName).font(.footnote.weight(.semibold)).foregroundStyle(Theme.textPrimary).lineLimit(1)
            PositionTag(player.position)
        }
        .frame(width: 92)
        .padding(.vertical, 10)
        .evCard()
    }
}
