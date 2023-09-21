// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "heures-creuses",
    platforms: [.iOS(.v16), .macOS(.v13)],
    products: [
        .library(name: "ApplianceFeature", targets: ["ApplianceFeature"]),
        .library(name: "AppFeature", targets: ["AppFeature"]),
        .library(name: "DataManagerDependency", targets: ["DataManagerDependency"]),
        .library(name: "Models", targets: ["Models"]),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.0.0"),
        .package(url: "https://github.com/tgrapperon/swift-dependencies-additions", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "ApplianceFeature",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "DependenciesAdditions", package: "swift-dependencies-additions"),
                "Models",
            ]
        ),
        .testTarget(
            name: "ApplianceFeatureTests",
            dependencies: ["ApplianceFeature"]
        ),
        .target(
            name: "AppFeature",
            dependencies: [
                "ApplianceFeature",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                "DataManagerDependency",
                "Models",
            ]
        ),
        .testTarget(
            name: "AppFeatureTests",
            dependencies: ["AppFeature"]
        ),
        .target(name: "DataManagerDependency", dependencies: []),
        .target(
            name: "Models",
            dependencies: [.product(name: "ComposableArchitecture", package: "swift-composable-architecture")]
        ),
    ]
)
