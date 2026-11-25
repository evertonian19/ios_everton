import Foundation

/// EA SPORTS FC 공식 선수 평가를 FM 식 능력치로 정리한 값. 원본(1~99)을 그대로 두고, 1~20 은 표시용 환산이다.
/// (대시보드 `backend/eafc.py` 와 같은 표·같은 규칙)
public struct PlayerRatings: Hashable, Codable, Sendable {
    public struct Attr: Hashable, Codable, Sendable, Identifiable {
        public let key: String
        public let label: String
        /// EA 원본 1~99.
        public let raw: Int
        public var id: String { key }
        /// FM 식 1~20 (원본 ÷ 5 반올림).
        public var fm: Int { PlayerRatings.to20(raw) }
    }

    public struct Group: Hashable, Codable, Sendable, Identifiable {
        public let id: String
        public let title: String
        public let attrs: [Attr]
    }

    public struct Position: Hashable, Codable, Sendable, Identifiable {
        public let code: String
        public let label: String
        public let main: Bool
        /// 피치 위 위치. x 0=왼쪽 1=오른쪽, y 0=상대 골문 1=우리 골문.
        public let x: Double
        public let y: Double
        public var id: String { code }
    }

    public struct Ability: Hashable, Codable, Sendable, Identifiable {
        public let label: String
        public let description: String
        public var id: String { label }
    }

    public let eaID: Int
    public let overall: Int
    public let groups: [Group]
    /// 이 선수의 상위 3개 능력치(키).
    public let top: [String]
    public let positions: [Position]
    public let foot: String?
    public let weakFoot: Int?
    public let skillMoves: Int?
    public let abilities: [Ability]
    public let eaTeam: String?
    /// 평가를 받아 온 시각.
    public let fetchedAt: Date

    public static func to20(_ raw: Int) -> Int { max(1, min(20, Int((Double(raw) / 5).rounded()))) }

    // MARK: 표

    static let outfield: [(id: String, title: String, rows: [(String, String)])] = [
        ("technical", "기술", [("finishing", "결정력"), ("longShots", "중거리 슛"), ("shotPower", "슈팅 파워"), ("volleys", "발리"),
                             ("penalties", "페널티"), ("shortPassing", "짧은 패스"), ("longPassing", "긴 패스"), ("crossing", "크로스"),
                             ("curve", "커브"), ("freeKickAccuracy", "프리킥"), ("dribbling", "드리블"), ("ballControl", "볼 컨트롤"),
                             ("headingAccuracy", "헤딩"), ("standingTackle", "스탠딩 태클"), ("slidingTackle", "슬라이딩 태클")]),
        ("mental", "정신", [("composure", "침착성"), ("reactions", "반응"), ("positioning", "위치 선정"), ("vision", "시야"),
                          ("aggression", "적극성"), ("interceptions", "가로채기"), ("defensiveAwareness", "수비 인식")]),
        ("physical", "신체", physicalRows),
    ]
    static let physicalRows: [(String, String)] = [("acceleration", "가속"), ("sprintSpeed", "주력"), ("agility", "민첩성"), ("balance", "균형"),
                                                   ("jumping", "점프"), ("stamina", "체력"), ("strength", "몸싸움")]
    static let keeper: [(id: String, title: String, rows: [(String, String)])] = [
        ("goalkeeping", "골키퍼", [("gkDiving", "다이빙"), ("gkHandling", "핸들링"), ("gkKicking", "킥"), ("gkPositioning", "위치 선정"), ("gkReflexes", "반응")]),
        ("mental", "정신", [("composure", "침착성"), ("reactions", "반응"), ("aggression", "적극성"), ("shortPassing", "짧은 패스"), ("longPassing", "긴 패스")]),
        ("physical", "신체", physicalRows),
    ]

    static let positionXY: [String: (Double, Double, String)] = [
        "GK": (0.5, 0.93, "골키퍼"), "RB": (0.85, 0.72, "우측 풀백"), "RWB": (0.88, 0.6, "우측 윙백"), "CB": (0.5, 0.78, "센터백"),
        "LB": (0.15, 0.72, "좌측 풀백"), "LWB": (0.12, 0.6, "좌측 윙백"), "CDM": (0.5, 0.62, "수비형 미드필더"), "CM": (0.5, 0.5, "중앙 미드필더"),
        "CAM": (0.5, 0.38, "공격형 미드필더"), "RM": (0.86, 0.48, "우측 미드필더"), "LM": (0.14, 0.48, "좌측 미드필더"),
        "RW": (0.84, 0.28, "우측 윙어"), "LW": (0.16, 0.28, "좌측 윙어"), "CF": (0.5, 0.22, "세컨드 스트라이커"), "ST": (0.5, 0.12, "스트라이커"),
    ]

    /// EA 원본 값들로 FM 식 구성을 만든다.
    public static func make(eaID: Int, overall: Int, stats: [String: Int], isKeeper: Bool, position: String, alternates: [String],
                            foot: String?, weakFoot: Int?, skillMoves: Int?, abilities: [Ability], team: String?, fetchedAt: Date) -> PlayerRatings {
        let groups = (isKeeper ? keeper : outfield).map { spec in
            Group(id: spec.id, title: spec.title, attrs: spec.rows.compactMap { key, label in
                stats[key].map { Attr(key: key, label: label, raw: $0) }
            })
        }
        let top = groups.flatMap(\.attrs).sorted { $0.raw > $1.raw }.prefix(3).map(\.key)
        let positions = ([position] + alternates).enumerated().compactMap { index, code -> Position? in
            guard let spot = positionXY[code] else { return nil }
            return Position(code: code, label: spot.2, main: index == 0, x: spot.0, y: spot.1)
        }
        return PlayerRatings(eaID: eaID, overall: overall, groups: groups, top: Array(top), positions: positions, foot: foot,
                             weakFoot: weakFoot, skillMoves: skillMoves, abilities: abilities, eaTeam: team, fetchedAt: fetchedAt)
    }
}
