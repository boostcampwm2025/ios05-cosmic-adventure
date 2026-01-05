import ProjectDescription

let workspace = Workspace(
    name: "cosmic-adventure",
    projects: [
        "iOS/App",
        "iOS/Modules/InputSystem",
        "iOS/Modules/Games",
        "iOS/Modules/GameEngineCore",
    ],
    additionalFiles: [
        .folderReference(path: "backend"),
        "README.md",
    ]
)
