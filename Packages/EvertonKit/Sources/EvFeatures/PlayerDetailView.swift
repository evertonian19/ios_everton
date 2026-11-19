import SwiftUI
import EvCore
import EvDesign

struct PlayerDetailView: View {
    let player: Player

    private var tiles: [(label: String, value: String)] {
        guard let s = player.stats else { return [] }
        if player.position == .goalkeeper {
            return [("출전", "\(s.appearances)"), ("출전 시간", "\(s.minutes)'"), ("선방", "\(s.saves)"),
                    ("실점", "\(s.conceded)"), ("패스 성공률", "\(s.passAccuracy)%"), ("경고", "\(s.yellow)")]
        }
        return [("출전", "\(s.appearances)"), ("출전 시간", "\(s.minutes)'"), ("골", "\(s.goals)"),
                ("도움", "\(s.assists)"), ("슈팅", "\(s.shots)"), ("유효슈팅", "\(s.shotsOnTarget)"),
                ("키패스", "\(s.keyPasses)"), ("패스 성공률", "\(s.passAccuracy)%"), ("태클", "\(s.tackles)"),
                ("드리블", "\(s.dribbles)"), ("경고", "\(s.yellow)"), ("퇴장", "\(s.red)")]
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                hero
                let metrics = PlayerMetrics.radar(for: player)
                if !metrics.isEmpty {
                    VStack(spacing: 4) {
                        SectionTitle("능력치 레이더")
                        RadarChart(labels: metrics.map(\.label), values: metrics.map(\.value))
                            .frame(maxWidth: 300)
                    }
                    .frame(maxWidth: .infinity)
                    .evCard()
                }
                if !tiles.isEmpty {
                    VStack(spacing: 8) {
                        SectionTitle("시즌 기록")
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                            ForEach(tiles, id: \.label) { tile in
                                VStack(spacing: 4) {
                                    Text(tile.value)
                                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                                        .foregroundStyle(Theme.textPrimary)
                                    Text(tile.label).font(.caption2).foregroundStyle(Theme.textSecondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                        }
                    }
                } else {
                    Text("이번 시즌 기록이 아직 없습니다.").font(.footnote).foregroundStyle(Theme.textSecondary)
                }
            }
            .padding(16)
        }
        .background(Theme.background)
        .navigationTitle(player.shortName)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var hero: some View {
        HStack(spacing: 16) {
            PlayerPhoto(url: player.photoURL, name: player.name, size: 104)
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    if let number = player.number {
                        Text("#\(number)").font(.title3.weight(.black)).foregroundStyle(Theme.gold)
                    }
                    PositionTag(player.position)
                }
                Text(player.name).font(.title3.weight(.bold)).foregroundStyle(Theme.textPrimary)
                Text([player.age.map { "\($0)세" }, player.nationality].compactMap { $0 }.joined(separator: " · "))
                    .font(.footnote).foregroundStyle(Theme.textSecondary)
            }
            Spacer(minLength: 0)
            VStack(spacing: 2) {
                RatingRing(player.stats?.rating, size: 58)
                Text("시즌 평점").font(.system(size: 9)).foregroundStyle(Theme.textSecondary)
            }
        }
        .padding(16)
        .background(Theme.heroGradient, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}
