import SwiftUI
import EvCore
import EvDesign

struct FixturesView: View {
    @Environment(AppModel.self) private var model

    private enum Filter: Hashable { case all, upcoming, results }
    @State private var filter: Filter = .all

    private func filtered(_ matches: [Match]) -> [Match] {
        switch filter {
        case .all: return matches
        case .upcoming: return matches.filter { $0.phase != .finished }
        case .results: return matches.filter { $0.phase == .finished }
        }
    }

    private func grouped(_ matches: [Match]) -> [(month: String, items: [Match])] {
        var order: [String] = []
        var buckets: [String: [Match]] = [:]
        for match in matches {
            let key = Fmt.month(match.kickoff)
            if buckets[key] == nil { order.append(key) }
            buckets[key, default: []].append(match)
        }
        return order.map { ($0, buckets[$0] ?? []) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {
                    FMTabs([(Filter.all, "전체"), (Filter.upcoming, "예정"), (Filter.results, "결과")], selection: $filter)
                    LoadStateView(state: model.matches, retry: { await model.loadMatches() }) { matches in
                        VStack(spacing: 10) {
                            ForEach(grouped(filtered(matches)), id: \.month) { group in
                                FMPanel(group.month, trailing: "\(group.items.count)경기") {
                                    VStack(spacing: 0) {
                                        ForEach(group.items) { match in
                                            NavigationLink(value: match) { MatchRow(match: match) }.buttonStyle(.plain)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    SourceFooter()
                }
                .padding(10)
            }
            .background(Theme.background)
            .evBrandBars()
            .navigationTitle("일정")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable { await model.loadMatches() }
            .navigationDestination(for: Match.self) { MatchDetailView(match: $0) }
            .navigationDestination(for: Player.self) { PlayerDetailView(player: $0) }
        }
    }
}
