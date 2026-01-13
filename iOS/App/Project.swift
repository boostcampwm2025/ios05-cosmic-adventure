import ProjectDescription

let project = Project(
    name: "App",
    targets: [
        Target.target(
            name: "App",
            destinations: .iOS,
            product: .app,
            bundleId: "kr.codesqued.boostcamp10.ios05.cosmic-adventure",
            deploymentTargets: .iOS("18.0"),
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
                "API_BASE_URL": "$(API_BASE_URL)",
                "UIAppFonts": [
                  "Fonts/Pretendard-Thin.otf",
                  "Fonts/Pretendard-ExtraLight.otf",
                  "Fonts/Pretendard-Light.otf",
                  "Fonts/Pretendard-Regular.otf",
                  "Fonts/Pretendard-Medium.otf",
                  "Fonts/Pretendard-SemiBold.otf",
                  "Fonts/Pretendard-Bold.otf",
                  "Fonts/Pretendard-ExtraBold.otf",
                  "Fonts/Pretendard-Black.otf",
                ]
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
                .project(target: "NetworkKit", path: "../Modules/NetworkKit"),
                .project(target: "StorageKit", path: "../Modules/StorageKit"),
            ],
            settings: .settings(
                base: [
                    "DEVELOPMENT_TEAM": "B3PWYBKFUK",
                    "CODE_SIGN_STYLE": "Automatic",
                ],
                configurations: [
                    .debug(name: "Debug", xcconfig: "Environment.xcconfig"),
                    .release(name: "Release", xcconfig: "Environment.xcconfig")
                ]
            )
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
    ],
    resourceSynthesizers: [.assets(), .fonts()]
)
