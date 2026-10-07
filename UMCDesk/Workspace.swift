//
//  Workspace.swift
//  UMCDesk
//
//  Created by euijjang97 on 10/6/26.
//

import ProjectDescription

let workspace = Workspace(
    name: "UMCDesk",
    projects: [".", "Core/*", "Features/*"],
    schemes: [
        .scheme(
            name: "UMCDesk",
            shared: true,
            buildAction: .buildAction(targets: [.project(path: ".", target: "UMCDesk")]),
            testAction: .targets([
                .testableTarget(target: .project(path: ".", target: "UMCDeskTests")),
                .testableTarget(target: .project(path: "Core/DI", target: "CoreDITests")),
                .testableTarget(target: .project(path: "Core/Network", target: "CoreNetworkTests")),
            ]),
            runAction: .runAction(
                configuration: .debug,
                executable: .project(path: ".", target: "UMCDesk")
            )
        ),
    ],
    additionalFiles: ["Tuist/Package.swift"]
)
