import Foundation

public enum Fmt {
    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "M월 d일 (E)"
        return f
    }()

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "HH:mm"
        return f
    }()

    private static let monthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "yyyy년 M월"
        return f
    }()

    public static func day(_ date: Date) -> String { dayFormatter.string(from: date) }
    public static func time(_ date: Date) -> String { timeFormatter.string(from: date) }
    public static func month(_ date: Date) -> String { monthFormatter.string(from: date) }

    public static func rating(_ value: Double?) -> String {
        guard let value else { return "-" }
        return String(format: "%.1f", value)
    }

    public static func stat(_ value: Double, percent: Bool) -> String {
        let text = value == value.rounded() ? String(Int(value)) : String(format: "%.1f", value)
        return percent ? text + "%" : text
    }

    /// 남은 시간을 "2일 04:12:09" 형태로 만든다. 이미 지났으면 nil.
    public static func countdown(to date: Date, from now: Date = Date()) -> String? {
        let seconds = Int(date.timeIntervalSince(now))
        guard seconds > 0 else { return nil }
        let days = seconds / 86_400
        let hours = (seconds % 86_400) / 3_600
        let minutes = (seconds % 3_600) / 60
        let secs = seconds % 60
        let clock = String(format: "%02d:%02d:%02d", hours, minutes, secs)
        return days > 0 ? "\(days)일 \(clock)" : clock
    }
}

public extension Array where Element == Match {
    /// 가장 최근에 끝난 경기 n 개 (오래된 순).
    func recentResults(_ n: Int = 5) -> [Match] {
        Array(filter { $0.phase == .finished }.sorted { $0.kickoff < $1.kickoff }.suffix(n))
    }

    func nextMatch(after now: Date = Date()) -> Match? {
        filter { $0.phase == .live || ($0.phase == .upcoming && $0.kickoff >= now) }
            .min { $0.kickoff < $1.kickoff }
    }
}
