// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "EvertonKit",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "EvCore", targets: ["EvCore"]),
        .library(name: "EvNetworking", targets: ["EvNetworking"]),
        .library(name: "EvDesign", targets: ["EvDesign"]),
        .library(name: "EvFeatures", targets: ["EvFeatures"]),
    ],
    targets: [
        .target(name: "EvCore"),
        .target(name: "EvNetworking", dependencies: ["EvCore"]),
        .target(name: "EvDesign", dependencies: ["EvCore"]),
        .target(name: "EvFeatures", dependencies: ["EvCore", "EvNetworking", "EvDesign"]),
        .testTarget(name: "EvCoreTests", dependencies: ["EvCore"]),
        .testTarget(name: "EvNetworkingTests", dependencies: ["EvNetworking", "EvCore"]),
    ]
)
