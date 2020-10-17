// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BioSwift",
    products: [
        .library(
            name: "BioSwift",
            targets: ["BioSwift"]),
    ],
     targets: [
        .target(
            name: "BioSwift",
            dependencies: [],
            resources: [
               .copy("Resources/unimod.xml"),
               .copy("Resources/aminoacids.json"),
               .copy("Resources/elements.json"),
               .copy("Resources/enzymes.json"),
               .copy("Resources/functionalgroups.json"),
               .copy("Resources/hydropathy.json"),
            ]
        )
        .testTarget(
            name: "BioSwiftTests",
            dependencies: ["BioSwift"]),
    ]
)
