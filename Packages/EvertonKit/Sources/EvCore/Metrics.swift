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

/// 시즌 스탯을 레이더 차트용 6개 지표로 바꾼다. 필드 플레이어는 90분당 수치를 기준으로 한다.
public enum PlayerMetrics {
    public static func radar(for player: Player) -> [Metric] {
        guard let s = player.stats else { return [] }
        let games = max(Double(s.minutes) / 90, 1)

        if player.position == .goalkeeper {
            let faced = Double(s.saves + s.conceded)
            let saveRate = faced > 0 ? Double(s.saves) / faced : 0
            let cards = Double(s.yellow + 3 * s.red)
            return [
                Metric(label: "선방률", value: saveRate),
                Metric(label: "패스", value: Double(s.passAccuracy) / 100),
                Metric(label: "출전", value: Double(s.appearances) / 38),
                Metric(label: "시간", value: Double(s.minutes) / (38 * 90)),
                Metric(label: "페어플레이", value: 1 - min(cards / 6, 1)),
                Metric(label: "평점", value: ((s.rating ?? 6) - 5) / 4),
            ]
        }

        return [
            Metric(label: "슈팅", value: Double(s.shots) / games / 4),
            Metric(label: "유효슈팅", value: Double(s.shotsOnTarget) / games / 2),
            Metric(label: "키패스", value: Double(s.keyPasses) / games / 3),
            Metric(label: "드리블", value: Double(s.dribbles) / games / 3),
            Metric(label: "태클", value: Double(s.tackles) / games / 4),
            Metric(label: "패스", value: Double(s.passAccuracy) / 100),
        ]
    }

    /// 시즌 스탯에서 가장 높게 나온 지표 이름 2개. 데이터가 부족하면 빈 배열.
    public static func strengths(for player: Player, limit: Int = 2) -> [String] {
        guard let s = player.stats, s.minutes >= 180 else { return [] }
        let metrics = radar(for: player).filter { $0.value >= 0.35 }
        return metrics.sorted { $0.value > $1.value }.prefix(limit).map(\.label)
    }

    /// 평점 순 상위 선수. 출전이 너무 적은 선수는 우연히 높은 평점이 나오므로 제외한다.
    public static func topRated(_ players: [Player], limit: Int = 6, minAppearances: Int = 3) -> [Player] {
        let rated = players.filter { ($0.stats?.rating ?? 0) > 0 }
        let regulars = rated.filter { ($0.stats?.appearances ?? 0) >= minAppearances }
        let pool = regulars.isEmpty ? rated : regulars
        return Array(pool.sorted { ($0.stats?.rating ?? 0) > ($1.stats?.rating ?? 0) }.prefix(limit))
    }
}
