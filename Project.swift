import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: .Graphene,
    additionalBaseSettings: SettingsDictionary().allowAppExtensionAPIOnly(true),
    targets: [
        .target(
            name: .Graphene,
            dependencies: [
                .external(name: .Alamofire)
            ]
        ),
        .target(
            name: .GrapheneInspector,
            sources: "Inspector/**",
            dependencies: [
                .xctest,
                .target(name: .Graphene),
                .external(name: .Alamofire)
            ]
        ),
        .target(
            name: .GrapheneTests,
            product: .unitTests,
            sources: .defaultTestsPath,
            dependencies: [.target(name: .Graphene)]
        )
    ],
    additionalFiles: ["README.MD", "Package.swift"]
)
