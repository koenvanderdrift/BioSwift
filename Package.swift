// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "BioSwift",
    products: [
        .library(
            name: "BioSwift",
            targets: ["BioSwift"]
        ),
    ],
    targets: [
        .target(
            name: "BioSwift",
            path: "Sources/BioSwift"
        .testTarget(
            name: "BioSwiftTests",
            dependencies: ["BioSwift"]
        ),
    ]
)
