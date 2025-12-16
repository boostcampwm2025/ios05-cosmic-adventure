import ProjectDescription

let project = Project(
    name: "Engine",
    targets: [
        .target(
            name: "Engine",
            destinations: .iOS,
            product: .framework,
            bundleId: "dev.tuist.CosmicAdventure.Engine",
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
            name: "EngineTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.tuist.CosmicAdventure.EngineTests",
            infoPlist: .default,
            buildableFolders: [
                "Tests",
            ],
            dependencies: [.target(name: "Engine")]
        ),
    ]
)
