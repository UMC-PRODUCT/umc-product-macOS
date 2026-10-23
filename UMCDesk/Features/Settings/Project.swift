//
//  Project.swift
//  Settings
//
//  Created by euijjang97 on 10/20/26.
//

import ProjectDescription
import ProjectDescriptionHelpers

let isPrerelease = Environment.prerelease.getString(default: "0") == "1"

let project = featureProject(
    name: "Settings",
    settings: .settings(
        base: recommendedProjectSettings.base,
        configurations: [
            .debug(name: "Debug"),
            .release(name: "Release", settings: [
                "EXCLUDED_SOURCE_FILE_NAMES": .string(
                    isPrerelease ? "$(inherited)" : "$(inherited) PreviewAssets.xcassets"
                )
            ])
        ]
    ),
    presentationResources: .resources(["Presentation/Resources/**"]),
    includesDomainTests: true,
    includesDataTests: true,
    includesPresentationTests: true
)
