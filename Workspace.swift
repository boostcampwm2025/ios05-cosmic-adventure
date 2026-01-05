import ProjectDescription

let workspace = Workspace(
    name: "cosmic-adventure",
    projects: [
        "App",
        "Modules/InputSystem",
        "Modules/Games",
        "Modules/GameEngineCore",
    ],
    additionalFiles: [
        .folderReference(path: "backend"),
        "README.md",
    ]
)
