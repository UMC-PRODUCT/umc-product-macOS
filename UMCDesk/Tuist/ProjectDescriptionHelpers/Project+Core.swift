//
//  Project+Core.swift
//  ProjectDescriptionHelpers
//
//  Created by euijjang97 on 10/6/26.
//

import ProjectDescription

/// Creates a macOS Core framework with an optional test target.
public func coreProject(
    name: String,
    bundleIdSuffix: String,
    dependencies: [TargetDependency] = [],
    resources: ResourceFileElements? = nil,
    includesTests: Bool = false
) -> Project {
    var targets: [Target] = [
        .target(
            name: name,
            destinations: .macOS,
            product: .staticFramework,
            bundleId: "com.umc.product.macos.core.\(bundleIdSuffix)",
            deploymentTargets: macOSDeploymentTargets,
            sources: ["Sources/**"],
            resources: resources,
            dependencies: dependencies
        ),
    ]
    if includesTests {
        targets.append(
            .target(
                name: "\(name)Tests",
                destinations: .macOS,
                product: .unitTests,
                bundleId: "com.umc.product.macos.core.\(bundleIdSuffix).tests",
                deploymentTargets: macOSDeploymentTargets,
                infoPlist: .default,
                sources: ["Tests/**"],
                dependencies: [.target(name: name)]
            )
        )
    }
    return Project(name: name, settings: recommendedProjectSettings, targets: targets)
}
