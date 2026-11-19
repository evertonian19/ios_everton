import Foundation

public struct Metric: Hashable, Sendable {
    public let label: String
    /// 0...1 로 정규화된 값
    public let value: Double

    public init(label: String, value: Double) {
        self.label = label
        self.value = min(max(value, 0), 1)
    }
}

/// 시즌 누적 기록을 출전 1회당 수치로 바꿔 레이더·강점·TOP 목록에 쓴다.
/// 출처(ESPN)는 평점·패스·태클 같은 값을 주지 않으므로 실제로 있는 기록만 사용한다.
public enum PlayerMetrics {
    /// 이 값이면 레이더 가장자리(1.0)에 닿는 출전당 기준.
    enum Scale {
        static let goals = 0.6
        static let assists = 0.4
        static let shots = 3.0
        static let shotsOnTarget = 1.2
        static let foulsSuffered = 2.0
        static let cardRate = 0.4          // 출전당 카드 점수(경고 1, 퇴장 3)가 이 값이면 규율 0
        static let savesPerGame = 4.0
        static let concededPerGame = 2.5
    }
    public static let strengthMinAppearances = 3
    public static let strengthThreshold = 0.5

    public static func radar(for player: Player, teamGames: Int? = nil) -> [Metric] {
        guard let s = player.stats, s.appearances > 0 else { return [] }
        let apps = Double(s.appearances)
        let cards = Double(s.yellow + 3 * s.red) / apps
        let discipline = Metric(label: "규율", value: 1 - min(cards / Scale.cardRate, 1))

        if player.position == .goalkeeper {
            let faced = Double(s.saves + s.conceded)
            var list = [
                Metric(label: "선방률", value: faced > 0 ? Double(s.saves) / faced : 0),
                Metric(label: "경기당 선방", value: Double(s.saves) / apps / Scale.savesPerGame),
                Metric(label: "실점 억제", value: 1 - min(Double(s.conceded) / apps / Scale.concededPerGame, 1)),
                discipline,
            ]
            if let teamGames, teamGames > 0 {
                list.append(Metric(label: "출전률", value: apps / Double(teamGames)))
            }
            return list
        }

        return [
            Metric(label: "골", value: Double(s.goals) / apps / Scale.goals),
            Metric(label: "도움", value: Double(s.assists) / apps / Scale.assists),
            Metric(label: "슈팅", value: Double(s.shots) / apps / Scale.shots),
            Metric(label: "유효슈팅", value: Double(s.shotsOnTarget) / apps / Scale.shotsOnTarget),
            Metric(label: "파울 획득", value: Double(s.foulsSuffered) / apps / Scale.foulsSuffered),
            discipline,
        ]
    }

    /// 가장 높게 나온 지표 이름 최대 2개(규율 제외). 출전이 적으면 빈 배열.
    public static func strengths(for player: Player, limit: Int = 2, teamGames: Int? = nil) -> [String] {
        guard let s = player.stats, s.appearances >= strengthMinAppearances else { return [] }
        return radar(for: player, teamGames: teamGames)
            .filter { $0.value >= strengthThreshold && $0.label != "규율" }
            .sorted { $0.value > $1.value }
            .prefix(limit).map(\.label)
    }

    /// 공격 포인트(골+도움) 순, 동률이면 골 → 유효슈팅. 필드 플레이어만.
    public static func topContributors(_ players: [Player], limit: Int = 6) -> [Player] {
        let pool = players.filter {
            $0.position != .goalkeeper && ($0.stats?.appearances ?? 0) > 0 && ($0.stats?.contribution ?? 0) > 0
        }
        let sorted = pool.sorted { a, b in
            let (x, y) = (a.stats!, b.stats!)
            if x.contribution != y.contribution { return x.contribution > y.contribution }
            if x.goals != y.goals { return x.goals > y.goals }
            return x.shotsOnTarget > y.shotsOnTarget
        }
        return Array(sorted.prefix(limit))
    }
}
