// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "flasher",
    platforms: [.macOS(.v10_15)],
    products: [
        .executable(name: "flasher", targets: ["flasher"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git",
                 .upToNextMinor(from: "0.3.0")),
        .package(url: "https://github.com/dduan/Pathos.git",
                 .upToNextMinor(from: "0.4.0")),
    ],
    targets: [
        .target(name: "apue", path: "Sources/apue"),

        .target(
            name: "flasher",
            dependencies: [
                .target(name: "apue"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Pathos", package: "Pathos"),
            ]),
    ]
)
