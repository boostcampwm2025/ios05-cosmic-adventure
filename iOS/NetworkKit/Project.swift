import ProjectDescription

let project = Project(
    name: "NetworkKit",
    targets: [
        .target(
            name: "NetworkKit",
            destinations: .iOS,
            product: .framework,
            bundleId: "dev.tuist.CosmicAdventure.NetworkKit",
            deploymentTargets: .iOS("18.0"),
            infoPlist: .default,
            buildableFolders: [
                "Sources",
            ],
            dependencies: [
                .project(target: "Core", path: "../Core"),
            ]
        ),
        .target(
            name: "NetworkKitTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.tuist.CosmicAdventure.NetworkKitTests",
            infoPlist: .default,
            buildableFolders: [
                "Tests",
            ],
            dependencies: [.target(name: "NetworkKit")]
        ),
    ]
)
