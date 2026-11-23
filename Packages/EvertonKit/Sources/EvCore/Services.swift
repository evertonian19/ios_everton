import Foundation

public protocol FootballService: Sendable {
    func matches() async throws -> [Match]
    func detail(of match: Match) async throws -> MatchDetail
    func squad(of clubID: Int) async throws -> [Player]
    func clubs() async throws -> [ClubInfo]
    func standings() async throws -> [StandingRow]
    /// 최근 경기의 실제 선발·통계로 만든 베스트 11 과 전술 요약.
    func tactics(of clubID: Int) async throws -> TeamTactics
    func diagnostics() async -> DataReport
    /// 이 출처에서 에버턴을 가리키는 구단 ID.
    var homeTeamID: Int { get }
}

public extension FootballService {
    /// 기본 구단(Everton)의 스쿼드.
    func squad() async throws -> [Player] { try await squad(of: homeTeamID) }

    /// 전술 정보를 주지 않는 출처(API-Football·스냅샷)의 기본 동작.
    func tactics(of clubID: Int) async throws -> TeamTactics {
        throw ServiceError.server("이 데이터 출처는 베스트 11·전술 정보를 제공하지 않습니다.")
    }
}

public protocol NewsService: Sendable {
    func headlines() async throws -> [NewsItem]
}

public enum ServiceError: Error, LocalizedError, Sendable {
    case missingAPIKey
    case server(String)
    case badResponse(Int)

    public var errorDescription: String? {
        switch self {
        case .missingAPIKey: return "API 키가 설정되지 않았습니다."
        case .server(let message): return message
        case .badResponse(let code): return "서버 응답 오류 (\(code))"
        }
    }
}
