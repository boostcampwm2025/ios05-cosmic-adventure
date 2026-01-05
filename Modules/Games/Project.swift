import ProjectDescription

let project = Project(
    name: "Games",
    targets: [
        .target(
            name: "Games",
            destinations: .iOS,
            product: .framework,
            bundleId: "dev.tuist.iOS.Games",
            infoPlist: .default,
            sources: [
                "Sources/**"
            ],
            dependencies: [],
        )
    ]
)
