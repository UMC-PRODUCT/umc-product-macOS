//
//  Project+Feature.swift
//  ProjectDescriptionHelpers
//
//  Created by euijjang97 on 10/6/26.
//

import ProjectDescription

/// Creates Domain, Data and Presentation macOS frameworks for one Feature.
public func featureProject(
    name: String,
    domainExtraDependencies: [TargetDependency] = [],
    dataExtraDependencies: [TargetDependency] = [],
    presentationExtraDependencies: [TargetDependency] = [],
    dataResources: ResourceFileElements? = nil,
    presentationResources: ResourceFileElements? = nil,
    includesDomainTests: Bool = false,
    includesDataTests: Bool = false,
    includesPresentationTests: Bool = false,
    domainTestDependencies: [TargetDependency] = [],
    dataTestDependencies: [TargetDependency] = [],
    presentationTestDependencies: [TargetDependency] = []
) -> Project {
    let identifier = "com.umc.product.macos.feature.\(name.lowercased())"
    var targets: [Target] = [
        .target(
            name: "\(name)Domain",
            destinations: .macOS,
            product: .staticFramework,
            bundleId: "\(identifier).domain",
            deploymentTargets: macOSDeploymentTargets,
            sources: ["Domain/Sources/**"],
            dependencies: [
                .project(target: "UMCFoundation", path: .relativeToRoot("Core/Foundation")),
                .project(target: "CoreDomain", path: .relativeToRoot("Core/Domain")),
            ] + domainExtraDependencies
        ),
        .target(
            name: "\(name)Data",
            destinations: .macOS,
            product: .staticFramework,
            bundleId: "\(identifier).data",
            deploymentTargets: macOSDeploymentTargets,
            sources: ["Data/Sources/**"],
            resources: dataResources,
            dependencies: [
                .target(name: "\(name)Domain"),
                .project(target: "CoreNetwork", path: .relativeToRoot("Core/Network")),
            ] + dataExtraDependencies
        ),
        .target(
            name: "\(name)Presentation",
            destinations: .macOS,
            product: .staticFramework,
            bundleId: "\(identifier).presentation",
            deploymentTargets: macOSDeploymentTargets,
            sources: ["Presentation/Sources/**"],
            resources: presentationResources,
            dependencies: [
                .target(name: "\(name)Domain"),
                .project(target: "CoreRouting", path: .relativeToRoot("Core/Routing")),
                .project(target: "CoreDesignSystem", path: .relativeToRoot("Core/DesignSystem")),
                .project(target: "CoreUIComponents", path: .relativeToRoot("Core/UIComponents")),
            ] + presentationExtraDependencies
        ),
    ]

    let testLayers: [(String, Bool, [TargetDependency])] = [
        ("Domain", includesDomainTests, domainTestDependencies),
        ("Data", includesDataTests, dataTestDependencies),
        ("Presentation", includesPresentationTests, presentationTestDependencies),
    ]
    for (layer, enabled, dependencies) in testLayers where enabled {
        targets.append(
            .target(
                name: "\(name)\(layer)Tests",
                destinations: .macOS,
                product: .unitTests,
                bundleId: "\(identifier).\(layer.lowercased()).tests",
                deploymentTargets: macOSDeploymentTargets,
                infoPlist: .default,
                sources: ["\(layer)/Tests/**"],
                dependencies: [.target(name: "\(name)\(layer)")] + dependencies
            )
        )
    }
    return Project(name: name, settings: recommendedProjectSettings, targets: targets)
}
