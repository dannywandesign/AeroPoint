// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "AeroPointAgent",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "AeroPointAgent", targets: ["AeroPointAgent"])
    ],
    targets: [
        .executableTarget(
            name: "AeroPointAgent",
            path: "Sources/AeroPointAgent"
        ),
        .testTarget(
            name: "AeroPointAgentTests",
            dependencies: ["AeroPointAgent"],
            path: "Tests/AeroPointAgentTests"
        )
    ]
)
