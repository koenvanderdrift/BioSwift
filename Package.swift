// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BioSwift",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "BioSwift",
            targets: ["BioSwift"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-algorithms.git", .upToNextMajor(from: "0.2.1")),
        .package(url: "https://github.com/apple/swift-collections.git", .upToNextMajor(from: "0.0.3")),
    ],
    targets: [
        .target(
            name: "BioSwift",
            dependencies: [],
            resources: [
                .process("Resources"),
            ]
        ),
        .testTarget(
            name: "BioSwiftTests",
            dependencies: ["BioSwift"]
        ),
    ]
)
