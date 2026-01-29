import Foundation
import ProjectDescription

let xconfigPath = URL(fileURLWithPath: #file)
    .deletingLastPathComponent()
    .appendingPathComponent("Environment.xcconfig")
let xconfigExists = FileManager.default.fileExists(atPath: xconfigPath.path)

let project = Project(
    name: "App",
    targets: [
        Target.target(
            name: "App",
            destinations: .iOS,
            product: .app,
            bundleId: "kr.boostcamp10.ios05.cosmic-adventure",
            deploymentTargets: .iOS("18.0"),
            infoPlist: .extendingDefault(with: [
                "UILaunchScreen": .dictionary([:]),
                "NSCameraUsageDescription": .string("AR 게임 플레이를 위해 카메라 접근이 필요해요."),

                "NSLocalNetworkUsageDescription": .string("근거리 통신(로컬 네트워크)으로 연결하기 위해 필요해요."),

                "NSBonjourServices": .array([
                    .string("_cosmicadventure._tcp"),
                ]),

                "NSAppTransportSecurity": .dictionary([
                    "NSAllowsArbitraryLoads": .boolean(true)
                ]),
                "API_BASE_URL": .string("$(API_BASE_URL)"),

                "UIAppFonts": .array([
                    .string("Pretendard-Thin.otf"),
                    .string("Pretendard-ExtraLight.otf"),
                    .string("Pretendard-Light.otf"),
                    .string("Pretendard-Regular.otf"),
                    .string("Pretendard-Medium.otf"),
                    .string("Pretendard-SemiBold.otf"),
                    .string("Pretendard-Bold.otf"),
                    .string("Pretendard-ExtraBold.otf"),
                    .string("Pretendard-Black.otf"),
                ]),

                "CFBundleDisplayName": .string("CosmicAdventure"),

                "UISupportedInterfaceOrientations": .array([
                    .string("UIInterfaceOrientationPortrait"),
                ]),

                "UISupportedInterfaceOrientations~ipad": .array([
                    .string("UIInterfaceOrientationPortrait"),
                    .string("UIInterfaceOrientationPortraitUpsideDown"),
                    .string("UIInterfaceOrientationLandscapeLeft"),
                    .string("UIInterfaceOrientationLandscapeRight"),
                ])
            ]),
            sources: [
                "Sources/**"
            ],
            resources: [
                "Resources/**",
            ],
            dependencies: [
                .project(target: "Games", path: "../Modules/Games"),
                .project(target: "InputSystem", path: "../Modules/InputSystem"),
                .project(target: "GameEngineCore", path: "../Modules/GameEngineCore"),
                .project(target: "NetworkKit", path: "../Modules/NetworkKit"),
                .project(target: "StorageKit", path: "../Modules/StorageKit"),
                .project(target: "VideoKit", path: "../Modules/VideoKit"),
            ],
            settings: .settings(
                base: [
                    "DEVELOPMENT_TEAM": "AQCS8SYVV6",
                    "CODE_SIGN_STYLE": "Automatic",
                ],
                configurations: xconfigExists ? [
                    .debug(name: "Debug", xcconfig: "Environment.xcconfig"),
                    .release(name: "Release", xcconfig: "Environment.xcconfig")
                ] : [
                    .debug(name: "Debug"),
                    .release(name: "Release")
                ]
            )
        ),
        Target.target(
            name: "AppTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "kr.boostcamp10.ios05.cosmic-adventure-tests",
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
