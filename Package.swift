// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DBus",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "DBus", targets: ["DBus"]),
        .executable(name: "DBusUtil", targets: ["DBusUtil"]),
    ],
    dependencies: [
        .package(url: "https://github.com/LuizZak/MiniLexer.git", from: "0.11.0"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.65.0"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.6.3"),
        .package(url: "https://github.com/CoreOffice/XMLCoder.git", from: "0.17.1"),
    ],
    targets: [
        .target(
            name: "DBus",
            dependencies: [
                .product(name: "MiniLexer", package: "MiniLexer"),
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio"),
                .product(name: "XMLCoder", package: "XMLCoder"),
            ]),
        .testTarget(name: "DBusTests", dependencies: ["DBus"]),
        .executableTarget(
            name: "DBusUtil",
            dependencies: [
                "DBus", .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Logging", package: "swift-log"),
            ]),
    ]
)
