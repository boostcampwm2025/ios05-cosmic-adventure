import ProjectDescription

let project = Project(
    name: "GameEngineCore",
    targets: [
        Target.target(
            name: "GameEngineCore",
            destinations: .iOS,
            product: .framework,
            bundleId: "dev.tuist.iOS.GameEngineCore",
            deploymentTargets: .iOS("18.0"),
            infoPlist: .default,
            sources: [
                "Sources/**"
            ],
            dependencies: [],
        )
    ]
)
