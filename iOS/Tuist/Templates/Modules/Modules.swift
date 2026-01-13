import ProjectDescription

let moduleName: Template.Attribute = .required("name")

let template = Template(
    description: "Module template",
    attributes: [
        moduleName
    ],
    items: [
        .file(
            path: "Modules/\(moduleName)/Project.swift",
            templatePath: "Sources/Project.stencil"
        ),
        .file(
            path: "Modules/\(moduleName)/Sources/\(moduleName).swift",
            templatePath: "Sources/Modules.swift.stencil"
        )
    ]
)
