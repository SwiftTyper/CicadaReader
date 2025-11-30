// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TTSFeature",
    platforms: [
        .iOS(.v17),
    ],
    products: [
        .library(
            name: "TTSFeature",
            targets: ["TTSFeature"]
        ),
    ],
    targets: [
        .target(
            name: "TTSFeature",
            dependencies: [
                "ESpeakNG",
            ],
            path: "Sources/TTSFeature",
            exclude: ["Frameworks"],
        ),
        .binaryTarget(
            name: "ESpeakNG",
            path: "Sources/TTSFeature/Frameworks/ESpeakNG.xcframework"
        ),
    ]
)
