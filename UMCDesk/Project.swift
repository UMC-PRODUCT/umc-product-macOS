//
//  Project.swift
//  UMCDesk
//
//  Created by euijjang97 on 10/6/26.
//

import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "UMCDesk",
    options: .options(automaticSchemesOptions: .disabled),
    settings: recommendedProjectSettings,
    targets: [
        .target(
            name: "UMCDesk",
            destinations: .macOS,
            product: .app,
            productName: "UMC Desk",
            bundleId: "com.umc.product.macos",
            deploymentTargets: macOSDeploymentTargets,
            infoPlist: .extendingDefault(with: [
                "CFBundleDisplayName": "UMC Desk",
                "CFBundleName": "UMC Desk",
                "CFBundleShortVersionString": "$(MARKETING_VERSION)",
                "CFBundleVersion": "$(CURRENT_PROJECT_VERSION)",
                "LSApplicationCategoryType": "public.app-category.productivity",
                "BASE_URL": "$(BASE_URL)",
            ]),
            sources: ["UMCDesk/Sources/**"],
            resources: ["UMCDesk/Resources/**"],
            entitlements: .file(path: "UMCDesk.entitlements"),
            dependencies: [
                .project(target: "UMCFoundation", path: "Core/Foundation"),
                .project(target: "CoreDomain", path: "Core/Domain"),
                .project(target: "CoreNetwork", path: "Core/Network"),
                .project(target: "CoreDI", path: "Core/DI"),
                .project(target: "CoreRouting", path: "Core/Routing"),
                .project(target: "CoreDesignSystem", path: "Core/DesignSystem"),
                .project(target: "CoreUIComponents", path: "Core/UIComponents"),
                .project(target: "AuthDomain", path: "Features/Auth"),
                .project(target: "AuthData", path: "Features/Auth"),
                .project(target: "AuthPresentation", path: "Features/Auth"),
                .project(target: "HomeDomain", path: "Features/Home"),
                .project(target: "HomeData", path: "Features/Home"),
                .project(target: "HomePresentation", path: "Features/Home"),
                .project(target: "NoticeDomain", path: "Features/Notice"),
                .project(target: "NoticeData", path: "Features/Notice"),
                .project(target: "NoticePresentation", path: "Features/Notice"),
                .project(target: "ActivityDomain", path: "Features/Activity"),
                .project(target: "ActivityData", path: "Features/Activity"),
                .project(target: "ActivityPresentation", path: "Features/Activity"),
                .project(target: "CommunityDomain", path: "Features/Community"),
                .project(target: "CommunityData", path: "Features/Community"),
                .project(target: "CommunityPresentation", path: "Features/Community"),
                .project(target: "MatchingDomain", path: "Features/Matching"),
                .project(target: "MatchingData", path: "Features/Matching"),
                .project(target: "MatchingPresentation", path: "Features/Matching"),
                .project(target: "ProjectWorkspaceDomain", path: "Features/ProjectWorkspace"),
                .project(target: "ProjectWorkspaceData", path: "Features/ProjectWorkspace"),
                .project(target: "ProjectWorkspacePresentation", path: "Features/ProjectWorkspace"),

            ],
            settings: .settings(base: [
                "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
                "PRODUCT_MODULE_NAME": "UMCDesk",
            ], configurations: [
                .debug(name: .debug, xcconfig: "Secrets/Shared.xcconfig"),
                .release(name: .release, xcconfig: "Secrets/Shared.xcconfig"),
            ])
        ),
        .target(
            name: "UMCDeskTests",
            destinations: .macOS,
            product: .unitTests,
            bundleId: "com.umc.product.macos.tests",
            deploymentTargets: macOSDeploymentTargets,
            infoPlist: .default,
            sources: ["UMCDesk/Tests/**"],
            dependencies: [.target(name: "UMCDesk")]
        ),
    ]
)
