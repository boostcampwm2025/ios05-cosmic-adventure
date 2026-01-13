import ProjectDescription

let workspace = Workspace(
    name: "cosmic-adventure",
    projects: [
        "iOS/App",
        "iOS/Modules/**"
    ],
    additionalFiles: [
        .folderReference(path: "backend"),
        "README.md",
    ]
)
