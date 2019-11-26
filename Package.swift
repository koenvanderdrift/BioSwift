// swift-tools-version:5.1
/**
*  BioSwift
*  Copyright (c) Koen van der Drift 2019
*  
*/

import PackageDescription

let package = Package(
    name: "BioSwift",
    products: [
        .library(name: "BioSwift", targets: ["BioSwift"])
    ],
    targets: [
        .target(name: "BioSwift"),
        .testTarget(name: "BioSwiftTests", dependencies: ["BioSwift"])
    ]
)
