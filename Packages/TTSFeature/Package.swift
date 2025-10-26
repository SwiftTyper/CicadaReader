// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TTSFeature",
    platforms: [
        .iOS(.v17),
        .macOS(.v13),
        .tvOS(.v16),
        .watchOS(.v9),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "TTSFeature",
            targets: ["TTSFeature"]
        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "TTSFeature",
            dependencies: [
                "ESpeakNG",
//                "FastClusterWrapper",
            ],
            path: "Sources/TTSFeature",
            exclude: ["Frameworks"],
//            swiftSettings: [
//                .define("ACCELERATE_NEW_LAPACK"),
//                .define("ACCELERATE_LAPACK_ILP64"),
//                .unsafeFlags([
//                    "-Xcc", "-DACCELERATE_NEW_LAPACK",
//                    "-Xcc", "-DACCELERATE_LAPACK_ILP64",
//                ]),
//            ]
        ),
        .binaryTarget(
            name: "ESpeakNG",
            path: "Sources/TTSFeature/Frameworks/ESpeakNG.xcframework"
        ),
    ]
)
