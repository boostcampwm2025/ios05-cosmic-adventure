import ProjectDescription

let project = Project(
    name: "InputSystem",
    targets: [
        .target(
            name: "InputSystem",
            destinations: .iOS,
            product: .framework,
            bundleId: "dev.tuist.iOS.InputSystem",
            infoPlist: .default,
            sources: [
                "Sources/**"
            ],
            dependencies: [],
        )
    ]
)
