import Foundation
import EvCore

/// 사진 후보 한 개. 출처 순위: manual(수동) < premierleague < commons (숫자가 작을수록 우선).
public struct PhotoCandidate: Hashable, Sendable {
    public enum Source: String, Codable, Sendable, Comparable {
        case manual, premierleague, commons
        var rank: Int { switch self { case .manual: 0; case .premierleague: 1; case .commons: 2 } }
        public static func < (a: Source, b: Source) -> Bool { a.rank < b.rank }
    }
    public let url: URL
    public let source: Source
    public let credit: PhotoCredit?

    public init(url: URL, source: Source, credit: PhotoCredit?) {
        self.url = url
        self.source = source
        self.credit = credit
    }
}

/// 후보 URL 을 실제로 내려받아 검증한 뒤 로컬 파일로 저장한다 (대시보드 photocache.py 와 같은 규칙).
/// 검증: HTTP 200 + 매직바이트(PNG/JPEG/WEBP) + 최소 크기(자리표시 이미지·오류 페이지 거부).
public actor PhotoCache {
    static let minBytes = 8_000
    static let maxBytes = 4_000_000

    private struct Stored: Codable { var file: String; var source: PhotoCandidate.Source; var credit: PhotoCredit?; var at: Date }

    private let directory: URL
    private let session: URLSession
    private var index: [Int: Stored]
    private var failed: [Int: Date] = [:]
    private let negativeTTL: TimeInterval = 6 * 3_600

    public init(session: URLSession = .shared, directory: URL? = nil) {
        self.session = session
        let base = directory ?? FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("PlayerPhotos")
        self.directory = base
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        if let data = try? Data(contentsOf: base.appendingPathComponent("index.json")),
           let loaded = try? JSONDecoder().decode([Int: Stored].self, from: data) {
            index = loaded
        } else {
            index = [:]
        }
    }

    /// 이미지 확장자(png/jpg/webp) 또는 nil. 크기가 작거나 이미지가 아니면 nil.
    static func sniff(_ data: Data) -> String? {
        guard data.count >= minBytes else { return nil }
        let head = [UInt8](data.prefix(12))
        if head.starts(with: [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]) { return "png" }
        if head.starts(with: [0xFF, 0xD8, 0xFF]) { return "jpg" }
        if head.count >= 12, head[0..<4].elementsEqual([0x52, 0x49, 0x46, 0x46]), head[8..<12].elementsEqual([0x57, 0x45, 0x42, 0x50]) { return "webp" }
        return nil
    }

    /// 선수 목록에 로컬 사진을 붙인다. 후보가 있는데 저장본이 없으면 내려받고(동시 6개), 더 좋은 출처가 생기면 업그레이드한다.
    public func apply(_ players: [Player], candidates: [Int: [PhotoCandidate]]) async -> [Player] {
        var work: [(Int, [PhotoCandidate])] = []
        for p in players {
            let cands = candidates[p.id] ?? []
            guard !cands.isEmpty else { continue }
            if let stored = index[p.id], FileManager.default.fileExists(atPath: directory.appendingPathComponent(stored.file).path) {
                let better = cands.filter { $0.source < stored.source }
                if !better.isEmpty, !recentlyFailed(p.id) { work.append((p.id, better)) }
            } else if !recentlyFailed(p.id) {
                work.append((p.id, cands))
            }
        }
        await withTaskGroup(of: (Int, Stored?).self) { group in
            var running = 0
            for (id, cands) in work {
                if running >= 6, let done = await group.next() { record(done); running -= 1 }
                group.addTask { (id, await self.download(id, cands)) }
                running += 1
            }
            for await done in group { record(done) }
        }
        saveIndex()
        return players.map { p in
            guard let stored = index[p.id] else { var q = p; q.photoURL = nil; q.photoCredit = nil; return q }
            var q = p
            q.photoURL = directory.appendingPathComponent(stored.file)
            q.photoCredit = stored.credit
            return q
        }
    }

    private func recentlyFailed(_ id: Int) -> Bool {
        failed[id].map { Date().timeIntervalSince($0) < negativeTTL } ?? false
    }

    private func record(_ result: (Int, Stored?)) {
        if let stored = result.1 { index[result.0] = stored } else { failed[result.0] = Date() }
    }

    private func saveIndex() {
        if let data = try? JSONEncoder().encode(index) { try? data.write(to: directory.appendingPathComponent("index.json")) }
    }

    /// 후보를 순서대로 시도해 처음 검증을 통과한 것을 저장한다.
    private nonisolated func download(_ id: Int, _ cands: [PhotoCandidate]) async -> Stored? {
        for c in cands.sorted(by: { $0.source < $1.source }) {
            var request = URLRequest(url: c.url)
            request.timeoutInterval = 12
            guard let (data, response) = try? await session.data(for: request),
                  (response as? HTTPURLResponse)?.statusCode == 200, data.count <= Self.maxBytes,
                  let ext = Self.sniff(data) else { continue }
            let name = "\(id).\(ext)"
            do { try data.write(to: directory.appendingPathComponent(name), options: .atomic) } catch { continue }
            return Stored(file: name, source: c.source, credit: c.credit, at: Date())
        }
        return nil
    }
}
