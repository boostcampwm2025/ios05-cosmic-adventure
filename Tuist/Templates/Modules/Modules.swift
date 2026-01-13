import ProjectDescription

let moduleName: Template.Attribute = .required("name")

let template = Template(
    description: "Module template",
    attributes: [
        moduleName
    ],
    items: [
        .file(
            path: "iOS/Modules/\(moduleName)/Project.swift",
            templatePath: "Sources/Project.stencil"
        ),
        .file(
            path: "iOS/Modules/\(moduleName)/Sources/\(moduleName).swift",
            templatePath: "Sources/Modules.swift.stencil"
        )
    ]
)
