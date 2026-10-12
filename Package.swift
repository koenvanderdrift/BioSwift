// swift-tools-version:6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BioSwift",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "BioSwift",
            targets: ["BioSwift"]
        ),
        .library(
            name: "BioSwiftNetworking",
            targets: ["BioSwiftNetworking"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "BioSwift",
            dependencies: [],
            resources: [
                .process("Resources")
            ]
        ),
        .target(
            name: "BioSwiftNetworking",
            dependencies: ["BioSwift"]
        ),
        .testTarget(
            name: "BioSwiftTests",
            dependencies: ["BioSwift"],
            path: "Tests",
            exclude: ["BioSwiftNetworking"]
        ),
        .testTarget(
            name: "BioSwiftNetworkingTests",
            dependencies: ["BioSwift", "BioSwiftNetworking"],
            path: "Tests/BioSwiftNetworking"
        ),
    ],
    swiftLanguageModes: [.v6]
)
