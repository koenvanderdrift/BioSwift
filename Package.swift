// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BioSwift",
    platforms: [.iOS(.v14), .macOS(.v10_12)],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "BioSwift",
            targets: ["BioSwift"]
        ),
    ],
    dependencies: [
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
            dependencies: ["BioSwift"],
            path: "Tests"
        ),
    ]
)
