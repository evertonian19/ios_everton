import Foundation

/// 응답 원문을 파일로 저장해 두는 간단한 캐시. 무료 API 호출 한도를 아끼기 위해 사용한다.
public actor DiskCache {
    private let directory: URL
    private let fileManager = FileManager.default

    public init(directory: URL? = nil) {
        let base = directory
            ?? fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("EvertonAPI")
        self.directory = base
        try? fileManager.createDirectory(at: base, withIntermediateDirectories: true)
    }

    private func fileURL(_ key: String) -> URL {
        let safe = key.map { $0.isLetter || $0.isNumber ? String($0) : "_" }.joined()
        return directory.appendingPathComponent(String(safe.suffix(180)))
    }

    /// maxAge 안에 저장된 데이터가 있으면 돌려준다. maxAge 가 nil 이면 나이와 무관하게 돌려준다.
    public func data(for key: String, maxAge: TimeInterval?) -> Data? {
        let url = fileURL(key)
        guard let attrs = try? fileManager.attributesOfItem(atPath: url.path),
              let modified = attrs[.modificationDate] as? Date,
              let data = try? Data(contentsOf: url) else { return nil }
        if let maxAge, Date().timeIntervalSince(modified) > maxAge { return nil }
        return data
    }

    public func store(_ data: Data, for key: String) {
        try? data.write(to: fileURL(key), options: .atomic)
    }

    public func clear() {
        try? fileManager.removeItem(at: directory)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
    }
}
