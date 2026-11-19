import Foundation
import EvCore

/// ESPN 공개 API(키 불필요)에서 프리미어리그 데이터를 읽는다. 비공식 API 라서 응답을 디스크에 캐시하고,
/// 네트워크가 실패하면 오래된 캐시를 대신 보여 준다. ESPN 이 주지 않는 값(평점·사진 등)은 만들지 않는다.
public struct ESPNService: FootballService {
    private let session: URLSession
    private let cache: DiskCache
    private let bio: WikidataBio
    private let site = "https://site.api.espn.com/apis/site/v2/sports/soccer/eng.1"
    private let v2 = "https://site.api.espn.com/apis/v2/sports/soccer/eng.1"

    public var homeTeamID: Int { EvertonInfo.teamID }

    public init(session: URLSession = .shared, cache: DiskCache = DiskCache()) {
        self.session = session
        self.cache = cache
        self.bio = WikidataBio(session: session, cache: cache)
    }

    private enum TTL {
        static let schedule: TimeInterval = 600
        static let standings: TimeInterval = 600
        static let teams: TimeInterval = 6 * 3_600
        static let roster: TimeInterval = 3_600
        static let summaryDone: TimeInterval = 86_400
        static let summaryLive: TimeInterval = 60
    }

    /// 신선한 캐시가 있으면 그대로 쓰고, 네트워크가 실패하면 오래된 캐시라도 돌려준다.
    private func fetch<T: Decodable>(_ urlString: String, ttl: TimeInterval, as type: T.Type) async throws -> T {
        guard let url = URL(string: urlString) else { throw ServiceError.server("잘못된 주소") }
        let key = url.absoluteString
        if let cached = await cache.data(for: key, maxAge: ttl), let decoded = try? JSONDecoder().decode(T.self, from: cached) {
            return decoded
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        do {
            let (data, response) = try await session.data(for: request)
            if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                throw ServiceError.badResponse(http.statusCode)
            }
            let decoded = try JSONDecoder().decode(T.self, from: data)
            await cache.store(data, for: key)
            return decoded
        } catch {
            if let stale = await cache.data(for: key, maxAge: nil), let decoded = try? JSONDecoder().decode(T.self, from: stale) {
                return decoded
            }
            throw error
        }
    }

    // MARK: - FootballService

    public func matches() async throws -> [Match] {
        let base = "\(site)/teams/\(homeTeamID)/schedule"
        async let past = fetch(base, ttl: TTL.schedule, as: ESPNSchedule.self)
        async let upcoming = fetch(base + "?fixture=true", ttl: TTL.schedule, as: ESPNSchedule.self)
        let lists = try await [past, upcoming]
        return ESPNMapping.schedule(lists)
    }

    public func detail(of match: Match) async throws -> MatchDetail {
        let ttl = match.phase == .live ? TTL.summaryLive : TTL.summaryDone
        let payload = try await fetch("\(site)/summary?event=\(match.id)", ttl: ttl, as: ESPNSummary.self)
        return MatchDetail(match: match,
                           stats: ESPNMapping.statLines(payload, homeID: match.home.id, awayID: match.away.id),
                           lineups: ESPNMapping.lineups(payload), events: ESPNMapping.events(payload))
    }

    public func squad(of clubID: Int) async throws -> [Player] {
        let payload = try await fetch("\(site)/teams/\(clubID)/roster", ttl: TTL.roster, as: ESPNRoster.self)
        let players = ESPNMapping.roster(payload)
        // 에버턴은 Wikidata 로 신상을 교차 검증한다. 다른 구단은 구단 QID 해결이 필요해 수동 보정만 적용한다.
        return clubID == EvertonInfo.teamID ? await bio.enrich(players) : PlayerBio.applyOverrides(players)
    }

    public func clubs() async throws -> [ClubInfo] {
        ESPNMapping.clubs(try await fetch("\(site)/teams", ttl: TTL.teams, as: ESPNTeams.self))
    }

    public func standings() async throws -> [StandingRow] {
        ESPNMapping.standings(try await fetch("\(v2)/standings", ttl: TTL.standings, as: ESPNStandings.self))
    }

    /// 시즌·일정·스쿼드가 기대(2026-27)와 맞는지 새로 확인한다.
    public func diagnostics() async -> DataReport {
        var report = DataReport(source: "ESPN 공개 API",
                                unavailable: ["선수 평점", "패스·태클·드리블·키패스·출전 시간", "선수 사진", "구단 창단연도·수용 인원"])
        do {
            let base = "\(site)/teams/\(homeTeamID)/schedule"
            let schedule = try await fetch(base, ttl: 0, as: ESPNSchedule.self)
            report.seasonName = schedule.season?.displayName
            report.seasonFound = (schedule.season?.displayName ?? "").contains(String(EvertonInfo.season))
        } catch { report.errors.append("시즌 조회 실패: \(error.localizedDescription)") }

        do {
            let matches = try await self.matches()
            report.fixtureCount = matches.count
            report.nextMatchDate = matches.nextMatch()?.kickoff
        } catch { report.errors.append("일정 조회 실패: \(error.localizedDescription)") }

        do {
            let players = try await squad()
            report.squadCount = players.count
            report.missingNumbers = players.filter { $0.number == nil }.count
            report.missingPhotos = players.count
        } catch { report.errors.append("스쿼드 조회 실패: \(error.localizedDescription)") }
        return report
    }
}
