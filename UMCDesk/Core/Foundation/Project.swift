//
//  Project.swift
//  UMCFoundation
//
//  Created by euijjang97 on 10/6/26.
//

import ProjectDescription
import ProjectDescriptionHelpers

let project = coreProject(
    name: "UMCFoundation",
    bundleIdSuffix: "foundation",
    dependencies: [
        .external(name: "UMCNetworkKit"),
    ]
)
