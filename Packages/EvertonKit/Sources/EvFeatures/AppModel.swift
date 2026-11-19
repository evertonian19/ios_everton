import SwiftUI
import Observation
import EvCore
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

    public init(football: FootballService, news: NewsService, isSample: Bool) {
        self.football = football
        self.news = news
        self.isSample = isSample
    }

    /// API 키가 없으면 샘플 데이터로 동작한다.
    public static func make(apiKey: String?) -> AppServices {
        let key = apiKey?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if key.isEmpty || key.hasPrefix("$(") {
            return AppServices(football: MockFootballService(), news: MockNewsService(), isSample: true)
        }
        return AppServices(football: APIFootballService(apiKey: key), news: RSSNewsService(), isSample: false)
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
}
