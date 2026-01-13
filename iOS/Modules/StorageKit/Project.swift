import ProjectDescription

let project = Project(
    name: "StorageKit",
    targets: [
        Target.target(
            name: "StorageKit",
            destinations: .iOS,
            product: .framework,
            bundleId: "dev.tuist.iOS.StorageKit",
            deploymentTargets: .iOS("18.0"),
            infoPlist: .default,
            sources: [
                "Sources/**"
            ],
            dependencies: [],
        )
    ]
)
