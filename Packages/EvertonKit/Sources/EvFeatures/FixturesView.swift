import SwiftUI
import EvCore
import EvDesign

struct FixturesView: View {
    @Environment(AppModel.self) private var model

    private enum Filter: String, CaseIterable, Identifiable {
        case all = "전체", upcoming = "예정", results = "결과"
        var id: String { rawValue }
    }

    @State private var filter: Filter = .all

    private func filtered(_ matches: [Match]) -> [Match] {
        switch filter {
        case .all: return matches
        case .upcoming: return matches.filter { $0.phase != .finished }
        case .results: return matches.filter { $0.phase == .finished }.reversed()
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
                VStack(spacing: 14) {
                    Picker("필터", selection: $filter) {
                        ForEach(Filter.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)

                    LoadStateView(state: model.matches, retry: { await model.loadMatches() }) { matches in
                        VStack(spacing: 18) {
                            ForEach(grouped(filtered(matches)), id: \.month) { group in
                                VStack(spacing: 8) {
                                    SectionTitle(group.month, trailing: "\(group.items.count)경기")
                                    VStack(spacing: 0) {
                                        ForEach(group.items) { match in
                                            NavigationLink(value: match) { MatchRow(match: match) }.buttonStyle(.plain)
                                            if match.id != group.items.last?.id { Divider().overlay(Theme.line.opacity(0.5)) }
                                        }
                                    }
                                    .evCard()
                                }
                            }
                        }
                    }
                }
                .padding(16)
            }
            .background(Theme.background)
            .navigationTitle("일정")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable { await model.loadMatches() }
            .navigationDestination(for: Match.self) { MatchDetailView(match: $0) }
            .navigationDestination(for: Player.self) { PlayerDetailView(player: $0) }
        }
    }
}
