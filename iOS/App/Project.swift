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
                    ])
                ]),
                "NSCameraUsageDescription": .string("AR 게임 플레이를 위해 카메라 접근이 필요해요."),

                "NSLocalNetworkUsageDescription": .string("근거리 통신(로컬 네트워크)으로 연결하기 위해 필요해요."),

                "NSBonjourServices": .array([
                    .string("_cosmicadventure._tcp"),
                ]),
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
