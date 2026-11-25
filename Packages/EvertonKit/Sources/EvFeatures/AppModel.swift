import SwiftUI
import Observation
import EvCore
import EvDesign
import EvNetworking

public enum LoadState<Value> {
    case idle
    case loading
    case loaded(Value)
    case failed(String)

    public var value: Value? {
        if case .loaded(let value) = self { return value }
        return nil
    }
}

public struct AppServices: Sendable {
    public let football: FootballService
    public let news: NewsService
    public let isSample: Bool
    /// 화면 구석에 표시할 데이터 출처 이름.
    public let sourceName: String

    public init(football: FootballService, news: NewsService, isSample: Bool, sourceName: String = "") {
        self.football = football
        self.news = news
        self.isSample = isSample
        self.sourceName = sourceName
    }

    /// 기본은 키가 필요 없는 ESPN 공개 API. API-Football 키를 넣으면 그쪽(사진·평점 포함)으로 전환한다.
    public static func make(apiKey: String?) -> AppServices {
        let key = apiKey?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if key.isEmpty || key.hasPrefix("$(") {
            return AppServices(football: ESPNService(), news: RSSNewsService(), isSample: false, sourceName: "ESPN")
        }
        return AppServices(football: APIFootballService(apiKey: key), news: RSSNewsService(), isSample: false,
                           sourceName: "API-Football")
    }

    /// 프리뷰·오프라인 확인용 스냅샷 서비스.
    public static var snapshot: AppServices {
        AppServices(football: MockFootballService(), news: MockNewsService(), isSample: true, sourceName: "스냅샷")
    }
}

@MainActor
@Observable
public final class AppModel {
    public let services: AppServices
    public var matches: LoadState<[Match]> = .idle
    public var squad: LoadState<[Player]> = .idle
    public var news: LoadState<[NewsItem]> = .idle
    public var standings: LoadState<[StandingRow]> = .idle
    public var clubs: LoadState<[ClubInfo]> = .idle
    /// 구단별 스쿼드(리그 탭에서 구단을 열 때 불러온다). 키는 구단 ID.
    public var rosters: [Int: LoadState<[Player]>] = [:]
    /// 구단별 베스트 11·전술(스쿼드 화면을 열 때 불러온다). 키는 구단 ID.
    public var tactics: [Int: LoadState<TeamTactics>] = [:]
    /// 선수별 EA 평가(선수 화면을 열 때 불러온다). 값이 nil 이면 '평가 없음'(확실히 매칭된 경우만 값이 있다).
    public var ratings: [Int: LoadState<PlayerRatings?>] = [:]
    private let eafc = EAFCRatings()

    public init(services: AppServices) {
        self.services = services
    }

    public func loadAll() async {
        async let a: Void = loadMatches()
        async let b: Void = loadSquad()
        async let c: Void = loadNews()
        async let d: Void = loadStandings()
        async let e: Void = loadClubs()
        _ = await (a, b, c, d, e)
    }

    public func loadMatches() async {
        if matches.value == nil { matches = .loading }
        do { matches = .loaded(try await services.football.matches()) }
        catch { if matches.value == nil { matches = .failed(error.localizedDescription) } }
    }

    public func loadSquad() async {
        if squad.value == nil { squad = .loading }
        do { squad = .loaded(try await services.football.squad()) }
        catch { if squad.value == nil { squad = .failed(error.localizedDescription) } }
    }

    public func loadNews() async {
        if news.value == nil { news = .loading }
        do { news = .loaded(try await services.news.headlines()) }
        catch { if news.value == nil { news = .failed(error.localizedDescription) } }
    }

    public func loadStandings() async {
        if standings.value == nil { standings = .loading }
        do { standings = .loaded(try await services.football.standings()) }
        catch { if standings.value == nil { standings = .failed(error.localizedDescription) } }
    }

    public func loadClubs() async {
        if clubs.value == nil { clubs = .loading }
        do { clubs = .loaded(try await services.football.clubs()) }
        catch { if clubs.value == nil { clubs = .failed(error.localizedDescription) } }
    }

    /// 에버턴이 이번 시즌 치른 경기 수(순위표 기준). 골키퍼 출전률 계산에 쓴다.
    public var teamGames: Int? {
        standings.value?.first(where: { EvertonInfo.isEverton($0.club.id) })?.played
    }

    public func reloadRoster(_ clubID: Int) async {
        rosters[clubID] = nil
        await loadRoster(clubID)
    }

    public func reloadTactics(_ clubID: Int) async {
        tactics[clubID] = nil
        await loadTactics(clubID)
    }

    public func loadTactics(_ clubID: Int) async {
        if tactics[clubID]?.value != nil { return }
        tactics[clubID] = .loading
        do { tactics[clubID] = .loaded(try await services.football.tactics(of: clubID)) }
        catch { tactics[clubID] = .failed(error.localizedDescription) }
    }

    public func loadRoster(_ clubID: Int) async {
        if rosters[clubID]?.value != nil { return }
        rosters[clubID] = .loading
        do { rosters[clubID] = .loaded(try await services.football.squad(of: clubID)) }
        catch { rosters[clubID] = .failed(error.localizedDescription) }
    }
}

// MARK: - EA 평가

extension AppModel {
    func loadRatings(for player: Player) async {
        if ratings[player.id]?.value != nil { return }
        if services.isSample { ratings[player.id] = .loaded(nil); return }
        ratings[player.id] = .loading
        ratings[player.id] = .loaded(await eafc.rating(for: player))
    }
}

// MARK: - 구단 색 찾기

extension AppModel {
    /// 구단 ID 로 팀 색을 찾는다. 구단 목록·순위표의 `code` 를 쓰고, 못 찾으면 에버턴 색.
    func palette(forClub id: Int) -> TeamPalette {
        if let code = clubs.value?.first(where: { $0.club.id == id })?.club.code { return .of(code: code) }
        if let code = standings.value?.first(where: { $0.club.id == id })?.club.code { return .of(code: code) }
        return .everton
    }

    /// 선수가 속한 구단의 팀 색. 불러온 스쿼드에서 찾고, 에버턴 스쿼드에 있으면 에버턴 색.
    func palette(forPlayer playerID: Int) -> TeamPalette {
        for (clubID, state) in rosters where state.value?.contains(where: { $0.id == playerID }) == true {
            return palette(forClub: clubID)
        }
        return .everton
    }
}
