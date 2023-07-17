// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "heures-creuses",
    platforms: [.iOS(.v16), .macOS(.v13)],
    products: [
        .library(name: "ApplianceFeature", targets: ["ApplianceFeature"]),
        .library(name: "AppFeature", targets: ["AppFeature"]),
        .library(name: "DevicesFeature", targets: ["DevicesFeature"]),
        .library(name: "Models", targets: ["Models"]),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", branch: "prerelease/1.0"),
    ],
    targets: [
        .target(
            name: "ApplianceFeature",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ]
        ),
        .target(
            name: "AppFeature",
            dependencies: [
                "ApplianceFeature",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                "DevicesFeature",
                "Models",
            ]
        ),
        .testTarget(
            name: "AppFeatureTests",
            dependencies: ["AppFeature"]
        ),
        .target(
            name: "DevicesFeature",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                "Models",
            ]
        ),
        .testTarget(
            name: "DevicesFeatureTests",
            dependencies: ["DevicesFeature"]
        ),
        .target(
            name: "Models",
            dependencies: [.product(name: "ComposableArchitecture", package: "swift-composable-architecture")]
        ),
    ]
)
