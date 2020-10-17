// swift-tools-version:5.2
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
            dependencies: []),
//            resources: [
//               .process("Resources/unimod.xml"),
//               .process("Resources/aminoacids.json"),
//               .process("Resources/elements.json"),
//               .process("Resources/enzymes.json"),
//               .process("Resources/functionalgroups.json"),
//               .process("Resources/hydropathy.json"),
//            ]
        .testTarget(
            name: "BioSwiftTests",
            dependencies: ["BioSwift"]),
    ]
)
