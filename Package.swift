// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "PocketPane",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "PocketPane", targets: ["PocketPane"])
    ],
    targets: [
        .target(name: "PocketPaneCore"),
        .executableTarget(
            name: "PocketPane",
            dependencies: ["PocketPaneCore"]
        ),
        .executableTarget(
            name: "PocketPaneCoreChecks",
            dependencies: ["PocketPaneCore"]
        )
    ]
)
