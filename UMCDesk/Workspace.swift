//
//  Workspace.swift
//  UMCDesk
//
//  Created by euijjang97 on 10/6/26.
//

import ProjectDescription

let workspace = Workspace(
    name: "UMCDesk",
    projects: [".", "Core/*", "Features/*"],
    schemes: [
        .scheme(
            name: "UMCDesk",
            shared: true,
            buildAction: .buildAction(targets: [.project(path: ".", target: "UMCDesk")]),
            testAction: .targets([
                .testableTarget(target: .project(path: ".", target: "UMCDeskTests")),
                .testableTarget(target: .project(
                    path: "Features/Auth", target: "AuthPresentationTests"
                )),
                .testableTarget(target: .project(
                    path: "Features/Settings", target: "SettingsDomainTests"
                )),
                .testableTarget(target: .project(
                    path: "Features/Settings", target: "SettingsDataTests"
                )),
                .testableTarget(target: .project(
                    path: "Features/Settings", target: "SettingsPresentationTests"
                )),
                .testableTarget(target: .project(
                    path: "Features/Matching", target: "MatchingDataTests"
                )),
                .testableTarget(target: .project(
                    path: "Features/Matching", target: "MatchingPresentationTests"
                )),
                .testableTarget(target: .project(
                    path: "Features/Home", target: "HomePresentationTests"
                )),
                .testableTarget(target: .project(
                    path: "Features/Home", target: "HomeDataTests"
                )),
                .testableTarget(target: .project(
                    path: "Features/Activity", target: "ActivityDataTests"
                )),
                .testableTarget(target: .project(
                    path: "Features/Activity", target: "ActivityPresentationTests"
                )),
                .testableTarget(target: .project(
                    path: "Features/Notice", target: "NoticeDomainTests"
                )),
                .testableTarget(target: .project(
                    path: "Features/Notice", target: "NoticeDataTests"
                )),
                .testableTarget(target: .project(
                    path: "Features/Notice", target: "NoticePresentationTests"
                )),
                .testableTarget(target: .project(
                    path: "Features/Community", target: "CommunityDataTests"
                )),
                .testableTarget(target: .project(
                    path: "Features/Community", target: "CommunityPresentationTests"
                )),
                .testableTarget(target: .project(
                    path: "Features/ProjectWorkspace", target: "ProjectWorkspaceDataTests"
                )),
                .testableTarget(target: .project(
                    path: "Features/ProjectWorkspace", target: "ProjectWorkspacePresentationTests"
                )),
                .testableTarget(target: .project(path: "Core/DI", target: "CoreDITests")),
                .testableTarget(target: .project(
                    path: "Core/DesignSystem", target: "CoreDesignSystemTests"
                )),
                .testableTarget(target: .project(path: "Core/Network", target: "CoreNetworkTests")),
            ]),
            runAction: .runAction(
                configuration: .debug,
                executable: .project(path: ".", target: "UMCDesk")
            )
        ),
    ],
    additionalFiles: ["Tuist/Package.swift"]
)
