//
//  Settings+Recommended.swift
//  ProjectDescriptionHelpers
//
//  Created by euijjang97 on 10/6/26.
//

import ProjectDescription

public let macOSDeploymentTargets: DeploymentTargets = .macOS("26.0")

public let recommendedProjectSettings: Settings = .settings(
    base: [
        "SWIFT_VERSION": "6.0",
        "SWIFT_STRICT_CONCURRENCY": "complete",
        "ENABLE_USER_SCRIPT_SANDBOXING": "YES",
        "ENABLE_MODULE_VERIFIER": "YES",
        "MARKETING_VERSION": "0.0.1",
        "CURRENT_PROJECT_VERSION": .string(Environment.buildNumber.getString(default: "1")),
        "CODE_SIGN_STYLE": "Automatic",
        "DEVELOPMENT_TEAM": .string(Environment.developmentTeam.getString(default: "8B8B4462NV")),
        "STRING_CATALOG_GENERATE_SYMBOLS": "YES",
    ]
)
