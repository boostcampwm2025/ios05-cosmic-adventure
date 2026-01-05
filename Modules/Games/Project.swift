import ProjectDescription

let project = Project(
    name: "Games",
    targets: [
        .init(
            name: "Games",
            platform: .iOS,
            product: .framework,
            bundleId: "dev.tuist.iOS.Games",
            deploymentTarget: .iOS(targetVersion: "18.0", devices: .iphone),
            infoPlist: .default,
            sources: [
                "Sources/**"
            ],
            dependencies: [],
        )
    ]
)
