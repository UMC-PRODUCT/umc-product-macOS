//
//  Project.swift
//  Settings
//
//  Created by euijjang97 on 10/20/26.
//

import ProjectDescription
import ProjectDescriptionHelpers

let project = featureProject(
    name: "Settings",
    settings: .settings(
        base: recommendedProjectSettings.base,
        configurations: [
            .debug(name: "Debug"),
            .release(name: "Release", settings: [
                "EXCLUDED_SOURCE_FILE_NAMES": "$(inherited) PreviewAssets.xcassets"
            ])
        ]
    ),
    presentationResources: .resources([
        .glob(pattern: "Presentation/Resources/**", excluding:
            Environment.prerelease.getString(default: "0") == "1"
                ? ["Presentation/Resources/PreviewAssets.xcassets/**"] : [])
    ]),
    includesDomainTests: true,
    includesDataTests: true,
    includesPresentationTests: true
)
