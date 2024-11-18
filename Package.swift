// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "pi-control-coordinator",
    platforms: [
        .macOS(.v15),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
        .package(url: "https://github.com/hummingbird-project/hummingbird.git", from: "2.3.0"),
        .package(url: "https://github.com/stephencelis/SQLite.swift.git", from: "0.15.3"),
        .package(url: "https://github.com/bouke/netservice.git", from: "0.8.1"),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", from: "1.8.3"),
        .package(url: "https://github.com/vapor/jwt-kit.git", from: "5.1.1"),
        .package(url: "https://github.com/behrang/YamlSwift.git", from: "3.4.4"),
        .package(url: "https://github.com/sroebert/mqtt-nio.git", from: "2.0.0"),
        .package(url: "https://github.com/PiControl/pi-control-rest-messages.git", branch: "main"),
        .package(url: "https://github.com/PiControl/PiControlMqttMessages.git", branch: "main")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "pi-control-coordinator",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Hummingbird", package: "hummingbird"),
                .product(name: "SQLite", package: "sqlite.swift"),
                .product(name: "NetService", package: "netservice"),
                .product(name: "CryptoSwift", package: "cryptoswift"),
                .product(name: "JWTKit", package: "jwt-kit"),
                .product(name: "Yaml", package: "yamlswift"),
                .product(name: "MQTTNIO", package: "mqtt-nio"),
                .product(name: "PiControlRestMessages", package: "pi-control-rest-messages"),
                .product(name: "PiControlMqttMessages", package: "PiControlMqttMessages")
            ]
        ),
    ]
)
