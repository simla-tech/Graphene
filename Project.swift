import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: .Graphene,
    additionalBaseSettings: SettingsDictionary().allowAppExtentionAPIOnly(true),
    targets: [
        Target(
            name: .Graphene,
            dependencies: [.carthage(.Alamofire)]
        ),
        Target(
            name: .GrapheneTests,
            product: .unitTests,
            sources: .defaultTestsPath,
            dependencies: [.target(name: .Graphene)]
        )
    ],
    additionalFiles: ["README.MD", "Package.swift", "Graphene.podspec"]
)
