import SwiftUI
import EvDesign

@MainActor
public struct RootView: View {
    @State private var model: AppModel

    public init(services: AppServices) {
        _model = State(initialValue: AppModel(services: services))
    }

    public var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("홈", systemImage: "house.fill") }
            FixturesView()
                .tabItem { Label("일정", systemImage: "calendar") }
            StandingsView()
                .tabItem { Label("순위", systemImage: "list.number") }
            SquadView()
                .tabItem { Label("스쿼드", systemImage: "person.3.fill") }
            NewsView()
                .tabItem { Label("뉴스", systemImage: "newspaper.fill") }
        }
        .tint(Theme.blue)
        .environment(model)
        .preferredColorScheme(.dark)
        .task { await model.loadAll() }
    }
}
