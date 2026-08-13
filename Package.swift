// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "LeoLauncher",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "LeoLauncher", targets: ["LeoLauncher"])
    ],
    targets: [
        .executableTarget(
            name: "LeoLauncher",
            path: "Sources/LeoLauncher"
        )
    ]
)
