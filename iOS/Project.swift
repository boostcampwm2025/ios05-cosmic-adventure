import ProjectDescription

let project = Project(
    name: "iOS",
    targets: [
        .target(
            name: "iOS",
            destinations: .iOS,
            product: .app,
            bundleId: "kr.codesqued.boostcamp10.ios05-cosmic-adventure",
            deploymentTargets: .iOS("18.0"),
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                    "NSCameraUsageDescription": "얼굴 인식을 통한 게임 조작을 위해 카메라 접근이 필요합니다.",
                    "UIRequiredDeviceCapabilities": [
                        "arkit",
                        "front-facing-camera",
                    ],
                ]
            ),
            buildableFolders: [
                "Sources",
                "Resources",
            ],
            dependencies: [
                .sdk(name: "ARKit", type: .framework, status: .required),
                .sdk(name: "SpriteKit", type: .framework, status: .required),
            ]
        ),
        .target(
            name: "iOSTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "kr.codesqued.boostcamp10.ios05-cosmic-adventure-tests",
            infoPlist: .default,
            buildableFolders: [
                "Tests",
            ],
            dependencies: [.target(name: "iOS")]
        ),
    ]
)
