import ProjectDescription

let project = Project(
    name: "App",
    targets: [
        .init(
            name: "App",
            platform: .iOS,
            product: .app,
            bundleId: "kr.codesqued.boostcamp10.ios05.cosmic-adventure",
            deploymentTarget: .iOS(targetVersion: "18.0", devices: .iphone),
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                ]
            ),
            sources: [
                "Sources/**"
            ],
            resources: [
                "Resources/**"
            ],
            dependencies: [
                .project(target: "Games", path: "../Modules/Games"),
                .project(target: "InputSystem", path: "../Modules/InputSystem"),
                .project(target: "GameEngineCore", path: "../Modules/GameEngineCore"),
            ]
        ),
        .init(
            name: "AppTests",
            platform: .iOS,
            product: .unitTests,
            bundleId: "kr.codesqued.boostcamp10.ios05.cosmic-adventure-tests",
            deploymentTarget: .iOS(targetVersion: "18.0", devices: .iphone),
            infoPlist: .default,
            sources: [
                "Tests/**"
            ],
            dependencies: [
                .target(name: "App")
            ]
        ),
    ]
)
