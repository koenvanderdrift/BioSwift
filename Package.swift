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
        .testTarget(
            name: "BioSwiftTests",
            dependencies: ["BioSwift"],
            path: "Tests"
        ),
    ],
    swiftLanguageModes: [.v6]
)
