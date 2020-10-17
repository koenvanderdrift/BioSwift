// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BioSwift",
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "BioSwift",
            targets: ["BioSwift"]
        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "BioSwift",
            resources: [
               .process("Resources/unimod.xml"),
               .process("Resources/aminoacids.json"),
               .process("Resources/elements.json"),
               .process("Resources/enzymes.json"),
               .process("Resources/functionalgroups.json"),
               .process("Resources/hydropathy.json")
            ]
        ),
        .testTarget(
            name: "BioSwiftTests",
            dependencies: ["BioSwift"]
        ),
    ]
)
