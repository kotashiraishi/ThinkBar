// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "ThinkBarCore",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
        .visionOS(.v1),
    ],
    products: [
        .library(
            name: "ThinkBarCore",
            targets: ["ThinkBarCore"]
        ),
    ],
    targets: [
        .target(
            name: "ThinkBarCore"
        ),
        .testTarget(
            name: "ThinkBarCoreTests",
            dependencies: ["ThinkBarCore"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
