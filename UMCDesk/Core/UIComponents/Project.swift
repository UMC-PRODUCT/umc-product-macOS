//
//  Project.swift
//  CoreUIComponents
//
//  Created by euijjang97 on 10/6/26.
//

import ProjectDescription
import ProjectDescriptionHelpers

let project = coreProject(
    name: "CoreUIComponents",
    bundleIdSuffix: "uicomponents",
    dependencies: [
        .project(target: "CoreDesignSystem", path: .relativeToRoot("Core/DesignSystem")),
    ]
)
