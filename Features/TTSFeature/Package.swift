// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

//@software{FluidInferenceTeam_FluidAudio_2024,
//  author = {{FluidInference Team}},
//  title = {{FluidAudio: Local Speaker Diarization, ASR, and VAD for Apple Platforms}},
//  year = {2024},
//  month = {12},
//  version = {0.7.0},
//  url = {https://github.com/FluidInference/FluidAudio},
//  note = {Computer software}
//}

let package = Package(
    name: "TTSFeature",
    platforms: [
        .iOS(.v17),
        .macOS(.v13),
        .tvOS(.v16),
        .watchOS(.v9),
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
