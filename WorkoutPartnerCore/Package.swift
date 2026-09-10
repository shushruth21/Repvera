// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "WorkoutPartnerCore",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    products: [
        .library(name: "WorkoutPartnerCore", targets: ["WorkoutPartnerCore"])
    ],
    targets: [
        .target(name: "WorkoutPartnerCore"),
        .testTarget(
            name: "WorkoutPartnerCoreTests",
            dependencies: ["WorkoutPartnerCore"]
        )
    ]
)
