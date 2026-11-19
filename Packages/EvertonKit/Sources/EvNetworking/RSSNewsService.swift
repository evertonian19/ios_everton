import Foundation
import EvCore

/// RSS 피드에서 기사 목록을 읽는다. 피드 주소는 설정에서 바꿀 수 있다.
public struct RSSNewsService: NewsService {
    public static let defaultFeeds: [URL] = [
        URL(string: "https://feeds.bbci.co.uk/sport/football/teams/everton/rss.xml")!,
    ]

    private let feeds: [URL]
    private let session: URLSession
    private let cache: DiskCache

    public init(feeds: [URL] = RSSNewsService.defaultFeeds, session: URLSession = .shared,
                cache: DiskCache = DiskCache()) {
        self.feeds = feeds
        self.session = session
        self.cache = cache
    }

    public func headlines() async throws -> [NewsItem] {
        var all: [NewsItem] = []
        var lastError: Error?
        for feed in feeds {
            do {
                let data = try await load(feed)
                all += RSSParser.parse(data)
            } catch {
                lastError = error
            }
        }
        if all.isEmpty, let lastError { throw lastError }
        var seen = Set<String>()
        return all
            .filter { seen.insert($0.id).inserted }
            .sorted { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }
            .prefix(30)
            .map { $0 }
    }

    private func load(_ url: URL) async throws -> Data {
        let key = url.absoluteString
        if let cached = await cache.data(for: key, maxAge: 900) { return cached }
        do {
            let (data, _) = try await session.data(from: url)
            await cache.store(data, for: key)
            return data
        } catch {
            if let stale = await cache.data(for: key, maxAge: nil) { return stale }
            throw error
        }
    }
}

enum RSSParser {
    static func parse(_ data: Data) -> [NewsItem] {
        let delegate = Delegate()
        let parser = XMLParser(data: data)
        parser.delegate = delegate
        parser.parse()
        return delegate.items
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        return f
    }()

    static func stripTags(_ text: String) -> String {
        text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private final class Delegate: NSObject, XMLParserDelegate {
        var items: [NewsItem] = []
        private var inItem = false
        private var current = ""
        private var title = ""
        private var summary = ""
        private var link = ""
        private var guid = ""
        private var pubDate = ""
        private var image: URL?

        func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?,
                    qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
            current = ""
            if elementName == "item" {
                inItem = true
                title = ""; summary = ""; link = ""; guid = ""; pubDate = ""; image = nil
            } else if inItem, elementName == "media:thumbnail" || elementName == "enclosure" {
                if let value = attributeDict["url"], let url = URL(string: value) { image = url }
            }
        }

        func parser(_ parser: XMLParser, foundCharacters string: String) { current += string }

        func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
            current += String(decoding: CDATABlock, as: UTF8.self)
        }

        func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?,
                    qualifiedName qName: String?) {
            guard inItem else { return }
            switch elementName {
            case "title": title = current
            case "description": summary = current
            case "link": link = current
            case "guid": guid = current
            case "pubDate": pubDate = current
            case "item":
                inItem = false
                let url = URL(string: link.trimmingCharacters(in: .whitespacesAndNewlines))
                let id = guid.isEmpty ? link : guid
                guard !title.isEmpty, !id.isEmpty else { return }
                items.append(NewsItem(
                    id: id.trimmingCharacters(in: .whitespacesAndNewlines),
                    title: RSSParser.stripTags(title), summary: RSSParser.stripTags(summary),
                    link: url, date: RSSParser.dateFormatter.date(from: pubDate.trimmingCharacters(in: .whitespaces)),
                    imageURL: image))
            default: break
            }
        }
    }
}
