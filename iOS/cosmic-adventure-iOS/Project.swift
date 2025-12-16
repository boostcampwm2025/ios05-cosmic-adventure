import ProjectDescription

let project = Project(
    name: "cosmic-adventure-iOS",
    targets: [
        .target(
            name: "CosmicAdventure",
            destinations: .iOS,
            product: .app,
            bundleId: "dev.tuist.CosmicAdventure",
            deploymentTargets: .iOS("18.0"),
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                    "NSCameraUsageDescription": "얼굴 인식 기능을 사용하여 게임을 플레이하기 위해 카메라 권한이 필요합니다.",
                ]
            ),
            buildableFolders: [
                "Sources",
                "Resources",
            ],
            dependencies: [
                .project(target: "Game", path: "../Feature/Game"),
            ]
        ),
        .target(
            name: "CosmicAdventureTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.tuist.CosmicAdventureTests",
            infoPlist: .default,
            buildableFolders: [
                "Tests",
            ],
            dependencies: [.target(name: "CosmicAdventure")]
        ),
    ]
)
