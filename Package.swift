// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "VoiceSnap",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "VoiceSnap", targets: ["VoiceSnap"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/argmaxinc/WhisperKit.git",
            from: "0.15.0"
        ),
        .package(
            url: "https://github.com/pointfreeco/swift-composable-architecture",
            from: "1.23.1"
        ),
        .package(
            url: "https://github.com/soffes/HotKey.git",
            from: "0.2.1"
        ),
    ],
    targets: [
        .executableTarget(
            name: "VoiceSnap",
            dependencies: [
                "WhisperKit",
                .product(
                    name: "ComposableArchitecture",
                    package: "swift-composable-architecture"
                ),
                "HotKey",
            ]
        ),
        .testTarget(
            name: "VoiceSnapTests",
            dependencies: [
                "VoiceSnap",
                .product(
                    name: "ComposableArchitecture",
                    package: "swift-composable-architecture"
                ),
            ]
        ),
    ]
)
