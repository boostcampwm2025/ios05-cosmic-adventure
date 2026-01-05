import ProjectDescription

let project = Project(
    name: "GameEngineCore",
    targets: [
        .init(
            name: "GameEngineCore",
            platform: .iOS,
            product: .framework,
            bundleId: "dev.tuist.iOS.GameEngineCore",
            deploymentTarget: .iOS(targetVersion: "18.0", devices: .iphone),
            infoPlist: .default,
            sources: [
                "Sources/**"
            ],
            dependencies: [],
        )
    ]
)


