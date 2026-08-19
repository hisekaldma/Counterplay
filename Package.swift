// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Counterplay",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
    ],
    products: [
        .library(
            name: "Counterplay",
            targets: ["Counterplay"]),
    ],
    targets: [
        .target(
            name: "Counterplay",
            swiftSettings: [
                .enableUpcomingFeature("NonisolatedNonsendingByDefault")
            ]),
        .testTarget(
            name: "CounterplayTests",
            dependencies: ["Counterplay"]),
    ]
)
