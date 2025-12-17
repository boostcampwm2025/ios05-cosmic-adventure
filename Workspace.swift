import ProjectDescription

let workspace = Workspace(
    name: "cosmic-adventure",
    projects: [
        "iOS/cosmic-adventure-iOS",
        "iOS/Core",
        "iOS/FaceKit",
        "iOS/NetworkKit",
        "iOS/Engine",
        "iOS/Feature/Game",
    ],
    additionalFiles: [
        "README.md",
    ]
)
