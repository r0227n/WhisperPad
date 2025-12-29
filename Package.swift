// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "WhisperPad",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "WhisperPad", targets: ["WhisperPad"])
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
            name: "WhisperPad",
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
            name: "WhisperPadTests",
            dependencies: [
                "WhisperPad",
                .product(
                    name: "ComposableArchitecture",
                    package: "swift-composable-architecture"
                ),
            ]
        ),
    ]
)
