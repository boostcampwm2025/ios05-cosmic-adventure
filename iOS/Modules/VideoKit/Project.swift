import ProjectDescription
 
let project = Project(
    name: "VideoKit",
    targets: [
        Target.target(
            name: "VideoKit",
            destinations: .iOS,
            product: .framework,
            bundleId: "dev.tuist.iOS.VideoKit",
            deploymentTargets: .iOS("18.0"),
            infoPlist: .default,
            sources: [
                "Sources/**"
            ],
            dependencies: [],
        )
    ]
)
