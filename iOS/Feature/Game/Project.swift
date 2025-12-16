import ProjectDescription

let project = Project(
    name: "Game",
    targets: [
        .target(
            name: "Game",
            destinations: .iOS,
            product: .framework,
            bundleId: "dev.tuist.CosmicAdventure.Feature.Game",
            deploymentTargets: .iOS("18.0"),
            infoPlist: .default,
            buildableFolders: [
                "Sources",
            ],
            dependencies: [
                .project(target: "Core", path: "../../Core"),
                .project(target: "Engine", path: "../../Engine"),
                .project(target: "FaceKit", path: "../../FaceKit"),
            ]
        ),
        .target(
            name: "GameTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.tuist.CosmicAdventure.Feature.GameTests",
            infoPlist: .default,
            buildableFolders: [
                "Tests",
            ],
            dependencies: [.target(name: "Game")]
        ),
    ]
)
