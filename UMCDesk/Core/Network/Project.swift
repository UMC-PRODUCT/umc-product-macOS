//
//  Project.swift
//  CoreNetwork
//
//  Created by euijjang97 on 10/6/26.
//

import ProjectDescription
import ProjectDescriptionHelpers

let project = coreProject(
    name: "CoreNetwork",
    bundleIdSuffix: "network",
    dependencies: [
        .external(name: "UMCNetworkKit"),
        .project(target: "UMCFoundation", path: .relativeToRoot("Core/Foundation")),
        .project(target: "CoreDomain", path: .relativeToRoot("Core/Domain")),
        .sdk(name: "Security", type: .framework),
    ]
)
