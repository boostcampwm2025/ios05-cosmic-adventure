import ProjectDescription

let project = Project(
    name: "NetworkKit",
    targets: [
        Target.target(
            name: "NetworkKit",
            destinations: .iOS,
            product: .framework,
            bundleId: "dev.tuist.iOS.NetworkKit",
            deploymentTargets: .iOS("18.0"),
            infoPlist: .default,
            sources: [
                "Sources/**"
            ],
            dependencies: [],
        )
    ]
)
