import SwiftUI
import EvFeatures

@main
struct EvertonApp: App {
    private let services = AppServices.make(
        apiKey: Bundle.main.object(forInfoDictionaryKey: "API_FOOTBALL_KEY") as? String)

    var body: some Scene {
        WindowGroup {
            RootView(services: services)
        }
    }
}
