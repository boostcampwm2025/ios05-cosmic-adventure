import ProjectDescription

let project = Project(
    name: "iOS",
    targets: [
        .target(
            name: "iOS",
            destinations: .iOS,
            product: .app,
            bundleId: "kr.codesqued.boostcamp10.ios05.cosmic-adventure",
            deploymentTargets: .iOS("18.0"),
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                ]
            ),
            buildableFolders: [
                "Sources",
                "Resources",
            ],
            dependencies: []
        ),
        .target(
            name: "iOSTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "kr.codesqued.boostcamp10.ios05.cosmic-adventure-tests",
            infoPlist: .default,
            buildableFolders: [
                "Tests",
            ],
            dependencies: [.target(name: "iOS")]
        ),
    ]
)
