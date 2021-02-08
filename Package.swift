import PackageDescription

let package = Package(
    name: "Graphene",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(name: "Graphene", targets: ["Graphene"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire", from: "5.2")
    ],
    targets: [
        .target(name: "Fraphene",
                dependencies: ["Alamofire"],
                path: "Source")
    ],
    swiftLanguageVersions: [
        .v5
    ]
)
