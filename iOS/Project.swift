import ProjectDescription

let project = Project(
    name: "iOS",
    targets: [
        .target(
            name: "iOS",
            destinations: .iOS,
            product: .app,
            bundleId: "dev.tuist.iOS",
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
            bundleId: "dev.tuist.iOSTests",
            infoPlist: .default,
            buildableFolders: [
                "Tests",
            ],
            dependencies: [.target(name: "iOS")]
        ),
    ]
)
