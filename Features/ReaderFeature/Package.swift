// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ReaderFeature",
    platforms: [
        .iOS(.v26),
    ],
    products: [
        .library(
            name: "ReaderFeature",
            targets: ["ReaderFeature"]
        ),
    ],
    dependencies: [
        .package(path: "../TTSFeature"),
    ],
    targets: [
        .target(
            name: "ReaderFeature",
            dependencies: [
                "TTSFeature"
            ],
        ),

    ]
)
