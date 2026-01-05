import ProjectDescription

let project = Project(
    name: "InputSystem",
    targets: [
        Target.target(
            name: "InputSystem",
            destinations: .iOS,
            product: .framework,
            bundleId: "dev.tuist.iOS.InputSystem",
            deploymentTargets: .iOS("18.0"),
            infoPlist: .default,
            sources: [
                "Sources/**"
            ],
            dependencies: [],
        )
    ]
)
