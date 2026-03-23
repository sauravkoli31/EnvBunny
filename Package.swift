// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "EnvBunny",
    platforms: [
        .macOS(.v14),
    ],
    targets: [
        .executableTarget(
            name: "EnvBunny",
            path: "Sources",
            resources: [
                .process("Resources"),
            ]
        ),
    ]
)
