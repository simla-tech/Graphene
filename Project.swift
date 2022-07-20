import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: .Graphene,
    additionalBaseSettings: SettingsDictionary().allowAppExtensionAPIOnly(true),
    targets: [
        Target(
            name: .Graphene,
            dependencies: [
                .external(name: .Alamofire)
            ]
        ),
        Target(
            name: .GrapheneInspector,
            sources: "Inspector/**",
            dependencies: [
                .xctest,
                .target(name: .Graphene),
                .external(name: .Alamofire)
            ]
        ),
        Target(
            name: .GrapheneTests,
            product: .unitTests,
            sources: .defaultTestsPath,
            dependencies: [.target(name: .Graphene)]
        )
    ],
    additionalFiles: ["README.MD", "Package.swift"]
)
