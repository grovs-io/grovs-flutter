// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "grovs_flutter_plugin",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "grovs-flutter-plugin", targets: ["grovs_flutter_plugin"])
    ],
    dependencies: [
        .package(url: "https://github.com/grovs-io/grovs-iOS.git", from: "3.1.0")
    ],
    targets: [
        .target(
            name: "grovs_flutter_plugin",
            dependencies: [
                .product(name: "Grovs", package: "grovs-iOS")
            ],
            resources: [
                .process("Resources")
            ]
        )
    ]
)
