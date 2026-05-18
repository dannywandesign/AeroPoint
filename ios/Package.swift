// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AeroPoint",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(name: "AeroPointLib", targets: ["AeroPointLib"])
    ],
    targets: [
        .target(
            name: "AeroPointLib",
            path: "Sources/AeroPoint"
        ),
        .testTarget(
            name: "AeroPointTests",
            dependencies: ["AeroPointLib"],
            path: "Tests/AeroPointTests"
        )
    ]
)
