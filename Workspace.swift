import ProjectDescription

let workspace = Workspace(
    name: "cosmic-adventure",
    projects: [
        "iOS",
    ],
    additionalFiles: [
        .folderReference(path: "backend"),
        "README.md",
    ]
)
