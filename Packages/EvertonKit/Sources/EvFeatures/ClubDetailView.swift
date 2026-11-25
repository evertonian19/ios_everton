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
        let palette = model.palette(forClub: club.id)
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
        .environment(\.teamPalette, palette)
        .evBrandBars(tint: palette.main)
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
                .background(Color.white.opacity(0.92), in: Circle())
                .evGlow(model.palette(forClub: club.id).glow, active: true)
            Text(club.name).font(.title3.weight(.bold)).foregroundStyle(.white)
            if let standing {
                HStack(spacing: 6) {
                    StatTile(value: standing.rank, label: "순위", highlight: standing.rank <= 4 || standing.rank >= 18,
                             compact: true, tint: standing.rank >= 18 ? Color(hex: 0xFF5A5F) : Color(hex: 0xFFD84A))
                    StatTile(value: standing.points, label: "승점", compact: true)
                    StatTile(value: standing.won, label: "승", compact: true)
                    StatTile(value: standing.drawn, label: "무", compact: true)
                    StatTile(value: standing.lost, label: "패", compact: true)
                }
                FormBadges(form: standing.form)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .evHero()
    }
}

/// 최근 5경기 결과(W/D/L) 배지. 왼쪽부터 순서대로 튀어 나온다.
private struct FormBadges: View {
    let form: String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false

    var body: some View {
        let letters = Array(form.uppercased().filter { "WDL".contains($0) }.suffix(5))
        if !letters.isEmpty {
            HStack(spacing: 5) {
                Text("최근").font(.caption2.weight(.semibold)).foregroundStyle(Color.white.opacity(0.8))
                ForEach(letters.indices, id: \.self) { i in
                    Text(String(letters[i]))
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.white)
                        .frame(width: 22, height: 22)
                        .background(color(letters[i]), in: Circle())
                        .shadow(color: color(letters[i]).opacity(0.8), radius: 4)
                        .scaleEffect(shown ? 1 : 0.1)
                        .opacity(shown ? 1 : 0)
                        .animation(reduceMotion ? nil : .spring(duration: 0.45, bounce: 0.5).delay(0.4 + Double(i) * 0.1), value: shown)
                }
            }
            .onAppear { shown = true }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("최근 경기 \(String(letters))")
        }
    }

    private func color(_ letter: Character) -> Color {
        switch letter {
        case "W": return Color(hex: 0x1FAA59)
        case "L": return Color(hex: 0xE5484D)
        default: return Color(hex: 0x8A93A3)
        }
    }
}
