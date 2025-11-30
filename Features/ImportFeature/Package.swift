// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ImportFeature",
    platforms: [
        .iOS(.v26),
    ],
    products: [
        .library(
            name: "ImportFeature",
            targets: ["ImportFeature"]
        ),
    ],
    targets: [
        .target(
            name: "ImportFeature"
        ),

    ]
)
