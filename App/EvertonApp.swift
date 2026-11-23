import SwiftUI
import EvFeatures
import EvNetworking

@main
struct EvertonApp: App {
    private let services = AppServices.make(
        apiKey: Bundle.main.object(forInfoDictionaryKey: "API_FOOTBALL_KEY") as? String)

    init() { ImageCache.install() }

    var body: some Scene {
        WindowGroup {
            RootView(services: services)
        }
    }
}


