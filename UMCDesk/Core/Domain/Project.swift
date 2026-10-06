//
//  Project.swift
//  CoreDomain
//
//  Created by euijjang97 on 10/6/26.
//

import ProjectDescription
import ProjectDescriptionHelpers

let project = coreProject(
    name: "CoreDomain",
    bundleIdSuffix: "domain",
    dependencies: [
        .project(target: "UMCFoundation", path: .relativeToRoot("Core/Foundation")),
    ]
)
