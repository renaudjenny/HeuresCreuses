// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "heures-creuses",
    platforms: [.iOS(.v17), .macOS(.v14), .watchOS(.v10)],
    products: [
        .library(name: "ApplianceFeature", targets: ["ApplianceFeature"]),
        .library(name: "AppFeature", targets: ["AppFeature"]),
        .library(name: "DataManagerDependency", targets: ["DataManagerDependency"]),
        .library(name: "HomeWidget", targets: ["HomeWidget"]),
        .library(name: "OffPeak", targets: ["OffPeak"]),
        .library(name: "Models", targets: ["Models"]),
        .library(name: "SendNotification", targets: ["SendNotification"]),
        .library(name: "UserNotification", targets: ["UserNotification"]),
        .library(name: "UserNotificationsClientDependency", targets: ["UserNotificationsClientDependency"]),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.8.0"),
        .package(url: "https://github.com/tgrapperon/swift-dependencies-additions", from: "1.0.1"),
    ],
    targets: [
        .target(
            name: "ApplianceFeature",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                "DataManagerDependency",
                .product(name: "DependenciesAdditions", package: "swift-dependencies-additions"),
                "HomeWidget",
                "Models",
                "SendNotification",
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
                "Models",
                "OffPeak",
                "UserNotification",
            ]
        ),
        .testTarget(
            name: "AppFeatureTests",
            dependencies: ["AppFeature"]
        ),
        .target(
            name: "DataManagerDependency",
            dependencies: [.product(name: "ComposableArchitecture", package: "swift-composable-architecture")]
        ),
        .target(name: "HomeWidget"),
        .target(
            name: "OffPeak",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                "HomeWidget",
                "Models",
                "SendNotification",
            ]
        ),
        .testTarget(
            name: "OffPeakTests",
            dependencies: ["OffPeak"]
        ),
        .target(
            name: "Models",
            dependencies: [.product(name: "ComposableArchitecture", package: "swift-composable-architecture")]
        ),
        .testTarget(
            name: "ModelsTests",
            dependencies: ["Models"]
        ),
        .target(
            name: "SendNotification",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "DependenciesAdditions", package: "swift-dependencies-additions"),
                "Models",
                "UserNotificationsClientDependency",
            ]
        ),
        .target(
            name: "UserNotification",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "DependenciesAdditions", package: "swift-dependencies-additions"),
                "HomeWidget",
                "Models",
                "UserNotificationsClientDependency",
            ]
        ),
        .testTarget(name: "UserNotificationTests", dependencies: ["UserNotification"]),
        .target(
            name: "UserNotificationsClientDependency",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                "DataManagerDependency",
                .product(name: "DependenciesAdditions", package: "swift-dependencies-additions"),
            ]
        )
    ]
)
