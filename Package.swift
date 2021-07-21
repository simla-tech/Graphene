// swift-tools-version:5.3.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Graphene",
    platforms: [.iOS(.v12), .macOS(.v10_13)],
    products: [
        .library(name: "Graphene", targets: ["Graphene"])
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire", .upToNextMajor(from: "5.2.0"))
    ],
    targets: [
        .target(
            name: "Graphene",
            dependencies: ["Alamofire"],
            path: "Sources"
        ),
        .testTarget(
            name: "GrapheneTests",
            dependencies: ["Graphene"],
            path: "Tests"
        )
    ]
)
