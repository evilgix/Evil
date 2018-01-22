// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Evil",
    dependencies: [
        .package(url: "https://github.com/evilgix/Preprocessing", from: "1.0.5")
    ],
    targets: [
        .target(
            name: "Evil",
            dependencies: [
                "DividerKit"
            ]
        ),
        .target(
            name: "DividerKit",
            dependencies: [
                "Preprocessing"
            ]
        ),
        .target(
            name: "Divider",
            dependencies: [
                "DividerKit"
        ]),
    ]
)
