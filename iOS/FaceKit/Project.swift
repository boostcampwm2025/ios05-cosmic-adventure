import ProjectDescription

let project = Project(
    name: "FaceKit",
    targets: [
        .target(
            name: "FaceKit",
            destinations: .iOS,
            product: .framework,
            bundleId: "dev.tuist.CosmicAdventure.FaceKit",
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
            name: "FaceKitTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.tuist.CosmicAdventure.FaceKitTests",
            infoPlist: .default,
            buildableFolders: [
                "Tests",
            ],
            dependencies: [.target(name: "FaceKit")]
        ),
    ]
)
