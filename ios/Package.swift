// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AeroPoint",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(name: "AeroPoint", targets: ["AeroPoint"])
    ],
    targets: [
        .target(
            name: "AeroPoint",
            path: "Sources/AeroPoint"
        ),
        .testTarget(
            name: "AeroPointTests",
            dependencies: ["AeroPoint"],
            path: "Tests/AeroPointTests"
        )
    ]
)
