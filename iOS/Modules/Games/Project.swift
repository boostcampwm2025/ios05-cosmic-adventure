import ProjectDescription

let project = Project(
    name: "Games",
    targets: [
        Target.target(
            name: "Games",
            destinations: .iOS,
            product: .framework,
            bundleId: "dev.tuist.iOS.Games",
            deploymentTargets: .iOS("18.0"),
            infoPlist: .default,
            sources: [
                "Sources/**"
            ],
            dependencies: [],
        )
    ]
)
