import ProjectDescription

let project = Project(
    name: "Core",
    targets: [
        .target(
            name: "Core",
            destinations: .iOS,
            product: .framework,
            bundleId: "dev.tuist.CosmicAdventure.Core",
            deploymentTargets: .iOS("18.0"),
            infoPlist: .default,
            buildableFolders: [
                "Sources",
            ],
            dependencies: []
        ),
        .target(
            name: "CoreTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.tuist.CosmicAdventure.CoreTests",
            infoPlist: .default,
            buildableFolders: [
                "Tests",
            ],
            dependencies: [.target(name: "Core")]
        ),
    ]
)
