//
//  Project.swift
//  Matching
//
//  Created by euijjang97 on 10/6/26.
//

import ProjectDescription
import ProjectDescriptionHelpers

let project = featureProject(
    name: "Matching",
    includesDataTests: true,
    includesPresentationTests: true,
    presentationTestDependencies: [.target(name: "MatchingDomain")]
)
