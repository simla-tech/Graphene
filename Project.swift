import ProjectDescription
import ProjectDescriptionHelpers

let project = Library(
    name: .Graphene,
    dependencies: TargetDependencies(
        thirdParty: [.Alamofire]
    ),
    test: TestTarget(
        name: .GrapheneTests
    ),
    additionalSettings: [
        .allowAppExtentionAPIOnly(true)
    ]
).project
