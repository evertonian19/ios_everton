import Foundation

/// 베스트 11 · 전술 계산 (대시보드 backend/ios_app.py 의 pick_xi / tactical_profile 과 같은 규칙).
/// 값은 최근 리그 경기의 실제 선발 명단과 경기 통계에서만 계산한다. 통계가 없는 항목은 nil 로 두고 만들어 내지 않는다.

/// 한 경기에서 한 구단의 기록 (라인업 + 통계 + 스코어).
public struct TeamSample: Sendable {
    public let matchID: Int
    public let opponent: String
    public let formation: String?
    public let starters: [LineupPlayer]
    public let goalsFor: Int
    public let goalsAgainst: Int
    /// 라벨("점유율", "슈팅" …) → 이 구단의 값.
    public let stats: [String: Double]

    public init(matchID: Int, opponent: String, formation: String?, starters: [LineupPlayer],
                goalsFor: Int, goalsAgainst: Int, stats: [String: Double]) {
        self.matchID = matchID
        self.opponent = opponent
        self.formation = formation
        self.starters = starters
        self.goalsFor = goalsFor
        self.goalsAgainst = goalsAgainst
        self.stats = stats
    }
}

public struct XIPlayer: Hashable, Sendable, Identifiable {
    public let id: Int
    public let name: String
    public let number: Int?
    /// "행:열" (1행 = 골키퍼).
    public let grid: String
    /// 최근 경기 중 선발로 나온 횟수.
    public let starts: Int

    public var shortName: String { name.split(separator: " ").last.map(String.init) ?? name }
}

public struct FormationCount: Hashable, Sendable {
    public let formation: String
    public let count: Int
}

public struct TacticalProfile: Hashable, Sendable {
    public var matches = 0
    public var possession: Double?
    public var shots: Double?
    public var shotsOnTarget: Double?
    public var passPct: Double?
    public var scored: Double?
    public var conceded: Double?
    public var tags: [String] = []
}

public struct TeamTactics: Hashable, Sendable {
    public let formation: String?
    public let formationCounts: [FormationCount]
    public let xi: [XIPlayer]
    public let profile: TacticalProfile
    /// 프로필 수치로 만든 설명 문장.
    public let summary: [String]
    /// 계산에 쓴 경기의 상대 이름 (오래된 순).
    public let opponents: [String]
}

public enum Tactics {
    /// 이 값을 넘거나 밑돌면 성향 태그를 붙인다.
    static let possessionHigh = 55.0, possessionLow = 45.0
    static let shotsHigh = 15.0, passHigh = 85.0, scoredHigh = 2.0, concededLow = 0.8
    public static let matchCount = 5

    /// 5경기에서 가장 많이 쓴 포메이션(동률이면 최근)을 고르고, 그 포메이션 경기 중
    /// 선발 11명의 '선발 횟수' 합이 가장 큰 경기(동률이면 최근)의 실제 선발을 쓴다. 샘플은 오래된 경기 → 최근 경기 순.
    public static func pickXI(_ samples: [TeamSample]) -> (formation: String, counts: [FormationCount], xi: [XIPlayer])? {
        let ok = samples.filter { s in
            s.formation != nil && s.starters.count == 11 && s.starters.allSatisfy { $0.grid != nil }
        }
        guard !ok.isEmpty else { return nil }

        var starts: [Int: Int] = [:]
        for s in samples { for p in s.starters { starts[p.id, default: 0] += 1 } }

        var counts: [String: (count: Int, last: Int)] = [:]
        for (i, s) in ok.enumerated() {
            guard let f = s.formation else { continue }
            let old = counts[f]?.count ?? 0
            counts[f] = (old + 1, i)
        }
        guard let formation = counts.max(by: { ($0.value.count, $0.value.last) < ($1.value.count, $1.value.last) })?.key else { return nil }

        var best: (score: Int, index: Int, sample: TeamSample)?
        for (i, s) in ok.enumerated() where s.formation == formation {
            let score = s.starters.reduce(0) { $0 + (starts[$1.id] ?? 0) }
            if best == nil || (score, i) >= (best!.score, best!.index) { best = (score, i, s) }
        }
        guard let chosen = best?.sample else { return nil }
        let xi = chosen.starters.map {
            XIPlayer(id: $0.id, name: $0.name, number: $0.number, grid: $0.grid ?? "9:9", starts: starts[$0.id] ?? 0)
        }
        let list = counts.map { FormationCount(formation: $0.key, count: $0.value.count) }
            .sorted { ($0.count, $1.formation) > ($1.count, $0.formation) }
        return (formation, list, xi)
    }

    private static func average(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        return ((values.reduce(0, +) / Double(values.count)) * 10).rounded() / 10
    }

    public static func profile(_ samples: [TeamSample]) -> TacticalProfile {
        func stat(_ key: String) -> Double? { average(samples.compactMap { $0.stats[key] }) }
        var p = TacticalProfile()
        p.matches = samples.count
        p.possession = stat("점유율")
        p.shots = stat("슈팅")
        p.shotsOnTarget = stat("유효슈팅")
        p.passPct = stat("패스 성공률")
        p.scored = average(samples.map { Double($0.goalsFor) })
        p.conceded = average(samples.map { Double($0.goalsAgainst) })
        if let v = p.possession {
            if v >= possessionHigh { p.tags.append("점유 지향") } else if v <= possessionLow { p.tags.append("역습·직선적") }
        }
        if let v = p.shots, v >= shotsHigh { p.tags.append("슈팅 많음") }
        if let v = p.passPct, v >= passHigh { p.tags.append("패스 정교") }
        if let v = p.scored, v >= scoredHigh { p.tags.append("다득점") }
        if let v = p.conceded, v <= concededLow { p.tags.append("단단한 수비") }
        return p
    }

    public static func summary(formation: String?, counts: [FormationCount], profile p: TacticalProfile) -> [String] {
        var out: [String] = []
        if let formation {
            let total = counts.reduce(0) { $0 + $1.count }
            let used = counts.first { $0.formation == formation }?.count ?? 0
            out.append("최근 \(total)경기 중 \(used)경기에서 \(formation) 포메이션을 썼습니다.")
        }
        if let v = p.possession {
            let style = v >= possessionHigh ? "공을 오래 소유하며 경기를 주도하는 편입니다."
                : v <= possessionLow ? "점유를 내주고 빠르게 전환하는 편입니다." : "상대와 비슷한 균형형입니다."
            out.append(String(format: "평균 점유율 %.1f%% — ", v) + style)
        }
        if let s = p.shots, let t = p.shotsOnTarget {
            out.append(String(format: "경기당 슈팅 %.1f개(유효 %.1f개)를 시도합니다.", s, t))
        }
        if let g = p.scored, let c = p.conceded {
            out.append(String(format: "경기당 %.1f득점·%.1f실점입니다.", g, c))
        }
        return out
    }

    public static func make(_ samples: [TeamSample]) -> TeamTactics {
        let picked = pickXI(samples)
        let prof = profile(samples)
        let counts = picked?.counts ?? []
        return TeamTactics(formation: picked?.formation, formationCounts: counts, xi: picked?.xi ?? [], profile: prof,
                           summary: summary(formation: picked?.formation, counts: counts, profile: prof),
                           opponents: samples.map(\.opponent))
    }
}
