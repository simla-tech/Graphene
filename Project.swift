import ProjectDescription
import ProjectDescriptionHelpers

let project = Library(
    name: .Graphene,
    options: .allowAppExtentionAPIOnly,
    dependencies: TargetDependencies(
        thirdParty: [.Alamofire]
    ),
    test: TestTarget(
        name: .GrapheneTests
    )
).project
