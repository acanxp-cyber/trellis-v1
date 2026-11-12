// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TrellisConcurrencyChecks",
    platforms: [
        .macOS(.v14),
        .iOS(.v18),
    ],
    products: [
        .library(
            name: "AudioTapBridge",
            targets: ["AudioTapBridge"]
        ),
    ],
    targets: [
        .target(
            name: "AudioTapBridge",
            path: "Sources/AudioTapBridge"
        ),
        .testTarget(
            name: "AudioTapBridgeTests",
            dependencies: ["AudioTapBridge"],
            path: "Tests/AudioTapBridgeTests"
        ),
    ]
)
