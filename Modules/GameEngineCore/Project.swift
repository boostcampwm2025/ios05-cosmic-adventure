import ProjectDescription

let project = Project(
    name: "GameEngineCore",
    targets: [
        .target(
            name: "GameEngineCore",
            destinations: .iOS,
            product: .framework,
            bundleId: "dev.tuist.iOS.GameEngineCore",
            infoPlist: .default,
            sources: [
                "Sources/**"
            ],
            dependencies: [],
        )
    ]
)


