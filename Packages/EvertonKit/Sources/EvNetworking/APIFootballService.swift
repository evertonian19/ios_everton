import Foundation
import EvCore

public struct APIFootballService: FootballService {
    private let apiKey: String
    private let session: URLSession
    private let cache: DiskCache
    private let baseURL = URL(string: "https://v3.football.api-sports.io")!

    public init(apiKey: String, session: URLSession = .shared, cache: DiskCache = DiskCache()) {
        self.apiKey = apiKey
        self.session = session
        self.cache = cache
    }

    // MARK: - 공통 요청

    /// 캐시가 신선하면 그대로 쓰고, 네트워크가 실패하면 오래된 캐시라도 돌려준다.
    private func fetch<T: Decodable>(_ path: String, _ query: [String: String], ttl: TimeInterval,
                                     as type: T.Type) async throws -> Envelope<T> {
        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        components.queryItems = query.sorted { $0.key < $1.key }.map { URLQueryItem(name: $0.key, value: $0.value) }
        let url = components.url!
        let key = url.absoluteString

        if let cached = await cache.data(for: key, maxAge: ttl),
           let decoded = try? JSONDecoder().decode(Envelope<T>.self, from: cached) {
            return decoded
        }

        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "x-apisports-key")
        request.timeoutInterval = 20
        do {
            let (data, response) = try await session.data(for: request)
            if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                throw ServiceError.badResponse(http.statusCode)
            }
            let decoded = try JSONDecoder().decode(Envelope<T>.self, from: data)
            if let message = decoded.errorMessage { throw ServiceError.server(message) }
            await cache.store(data, for: key)
            return decoded
        } catch {
            if let stale = await cache.data(for: key, maxAge: nil),
               let decoded = try? JSONDecoder().decode(Envelope<T>.self, from: stale) {
                return decoded
            }
            throw error
        }
    }

    // MARK: - FootballService

    public func matches() async throws -> [Match] {
        let result = try await fetch("fixtures",
                                     ["team": String(EvertonInfo.teamID), "season": String(EvertonInfo.season)],
                                     ttl: 600, as: [FixtureDTO].self)
        return result.response.compactMap(Mapping.match).sorted { $0.kickoff < $1.kickoff }
    }

    public func detail(of match: Match) async throws -> MatchDetail {
        let id = String(match.id)
        // 끝난 경기는 오래 캐시, 진행/예정 경기는 짧게.
        let ttl: TimeInterval = match.phase == .finished ? 86_400 : 60
        async let statsRequest = fetch("fixtures/statistics", ["fixture": id], ttl: ttl, as: [StatisticsDTO].self)
        async let lineupRequest = fetch("fixtures/lineups", ["fixture": id], ttl: ttl, as: [LineupDTO].self)
        async let playersRequest = fetch("fixtures/players", ["fixture": id], ttl: ttl, as: [FixturePlayersDTO].self)
        async let eventsRequest = fetch("fixtures/events", ["fixture": id], ttl: ttl, as: [EventDTO].self)

        let stats = (try? await statsRequest.response) ?? []
        let lineups = (try? await lineupRequest.response) ?? []
        let players = (try? await playersRequest.response) ?? []
        let events = (try? await eventsRequest.response) ?? []

        return MatchDetail(
            match: match,
            stats: Mapping.statLines(stats, homeID: match.home.id),
            lineups: Mapping.lineups(lineups, ratings: Mapping.ratings(players)),
            events: Mapping.events(events).filter { $0.isKey })
    }

    public func standings() async throws -> [StandingRow] {
        let result = try await fetch("standings",
                                     ["league": String(EvertonInfo.leagueID), "season": String(EvertonInfo.season)],
                                     ttl: 3_600, as: [StandingsDTO].self)
        return Mapping.standings(result.response)
    }

    /// 시즌·일정·스쿼드가 기대와 맞는지 캐시 없이 새로 확인한다.
    public func diagnostics() async -> DataReport {
        var report = DataReport()
        do {
            let leagues = try await fetch("leagues",
                                          ["id": String(EvertonInfo.leagueID), "season": String(EvertonInfo.season)],
                                          ttl: 0, as: [LeagueInfoDTO].self)
            if let season = leagues.response.first?.seasons.first(where: { $0.year == EvertonInfo.season }) {
                report.seasonFound = true
                report.seasonStart = season.start
                report.seasonEnd = season.end
            }
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
            report.missingPhotos = players.filter { $0.photoURL == nil }.count
        } catch { report.errors.append("스쿼드 조회 실패: \(error.localizedDescription)") }
        return report
    }

    public func clubs() async throws -> [ClubInfo] {
        let result = try await fetch("teams",
                                     ["league": String(EvertonInfo.leagueID), "season": String(EvertonInfo.season)],
                                     ttl: 86_400, as: [TeamEntryDTO].self)
        return result.response.map(Mapping.clubInfo).sorted { $0.club.name < $1.club.name }
    }

    public func squad(of clubID: Int) async throws -> [Player] {
        let squadResult = try await fetch("players/squads", ["team": String(clubID)],
                                          ttl: 86_400, as: [SquadDTO].self)
        let members = squadResult.response.first?.players ?? []

        // 시즌 스탯은 페이지 단위로 온다. 실패해도 스쿼드는 보여 준다.
        var statsByID: [Int: SeasonPlayerDTO] = [:]
        var page = 1
        var total = 1
        while page <= total && page <= 4 {
            guard let result = try? await fetch(
                "players",
                ["team": String(clubID), "season": String(EvertonInfo.season), "page": String(page)],
                ttl: 21_600, as: [SeasonPlayerDTO].self) else { break }
            for dto in result.response { statsByID[dto.player.id] = dto }
            total = result.paging?.total ?? 1
            page += 1
        }

        return members.map { member in
            let season = statsByID[member.id]
            return Player(
                id: member.id, name: member.name, number: member.number,
                position: Position(apiName: member.position), age: member.age ?? season?.player.age,
                nationality: season?.player.nationality,
                photoURL: (member.photo ?? season?.player.photo).flatMap(URL.init(string:)),
                stats: season.flatMap(Mapping.stats),
                heightCM: Mapping.number(season?.player.height), weightKG: Mapping.number(season?.player.weight),
                birthDate: Mapping.birthDate(season?.player.birth?.date), birthPlace: season?.player.birth?.place)
        }
        .sorted { ($0.number ?? 99) < ($1.number ?? 99) }
    }
}
