import ProjectDescription

let project = Project(
    name: "App",
    targets: [
        Target.target(
            name: "App",
            destinations: .iOS,
            product: .app,
            bundleId: "kr.codesqued.boostcamp10.ios05.cosmic-adventure",
            infoPlist: .extendingDefault(with: [
                "UILaunchScreen": .array([
                    .dictionary([
                        "UIColorName": .string(""),
                        "UIImageName": .string(""),
                    ],)
                ])
            ]),
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
        Target.target(
            name: "AppTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "kr.codesqued.boostcamp10.ios05.cosmic-adventure-tests",
            deploymentTargets: .iOS("18.0"),
            infoPlist: .default,
            sources: [
                "Tests/**"
            ],
            dependencies: [
                .target(name: "App")
            ]
        )
    ]
)
