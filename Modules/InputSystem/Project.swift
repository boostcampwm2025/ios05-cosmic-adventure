import ProjectDescription

let project = Project(
    name: "InputSystem",
    targets: [
        .init(
            name: "InputSystem",
            platform: .iOS,
            product: .framework,
            bundleId: "dev.tuist.iOS.InputSystem",
            deploymentTarget: .iOS(targetVersion: "18.0", devices: .iphone),
            infoPlist: .default,
            sources: [
                "Sources/**"
            ],
            dependencies: [],
        )
    ]
)
