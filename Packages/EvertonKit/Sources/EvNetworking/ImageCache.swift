import Foundation

/// 구단 엠블럼·선수 사진을 디스크에 캐시해 두 번째부터는 네트워크 없이 표시한다.
public enum ImageCache {
    public static func install() {
        URLCache.shared = URLCache(memoryCapacity: 50 * 1024 * 1024,
                                   diskCapacity: 300 * 1024 * 1024,
                                   directory: nil)
    }
}
