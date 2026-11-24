//
//  MatchingOperationsView.swift
//  MatchingPresentation
//
//  Created by euijjang97 on 11/22/26.
//

import CoreDesignSystem
import MatchingDomain
import SwiftUI

enum MatchingOperationsSection { case projects, statistics }

struct MatchingOperationsView: View {
    let section: MatchingOperationsSection
    let service: any MatchingUseCase
    let gisuId: String
    var chapterId: String?
    let canCreateOwn: Bool
    let canChooseOther: Bool
    let canReadAdjustment: Bool
    @State private var projectStatusValue: String?
    @State private var projectId: String?
    @State private var keyword = ""
    @State private var search = ""
    @State private var page = 0
    @State private var revision = 0
    @State private var creating = false

    var body: some View {
        if section == .statistics {
            MatchingStatisticsView(service: service, chapterId: chapterId,
                                   canReadAdjustment: canReadAdjustment)
                .id(chapterId)
        } else if let projectId {
            ProjectOperationsView(service: service, projectId: projectId, status: projectStatusValue) {
                self.projectId = nil
                revision += 1
            }
            .id(projectId)
        } else {
            VStack(alignment: .leading, spacing: UMCSpacing.value16) {
                HStack {
                    Text("내가 관리하는 프로젝트").umcTypography(.title1Bold)
                    Spacer()
                    if canCreateOwn || canChooseOther {
                        Button("프로젝트 만들기", systemImage: "plus") { creating = true }
                    }
                }
                HStack {
                    TextField("프로젝트 검색", text: $search)
                        .onSubmit { page = 0; keyword = search }
                    Button("검색") { page = 0; keyword = search }
                }
                OperationsLoad(key: [keyword, String(page), String(revision)], load: {
                    try await service.managedProjects(gisuId: gisuId, keyword: keyword, page: page)
                }) { result in
                    if result.projects.isEmpty {
                        ContentUnavailableView("관리 프로젝트가 없어요", systemImage: "folder")
                    } else {
                        VStack(alignment: .leading, spacing: UMCSpacing.value12) {
                            HStack {
                                Text("프로젝트").frame(maxWidth: .infinity, alignment: .leading)
                                Text("PM · 학교").frame(maxWidth: .infinity, alignment: .leading)
                                Text("상태").frame(width: 110, alignment: .leading)
                            }
                            .foregroundStyle(.secondary)
                            ForEach(result.projects, id: \.id) { project in
                                Divider()
                                Button {
                                    projectStatusValue = project.status
                                    projectId = project.id
                                } label: {
                                    HStack {
                                        Text(project.name ?? "제목 없는 초안")
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        Text(project.productOwner?.display ?? "—")
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        MatchingBadge(text: projectStatus(project.status))
                                            .frame(width: 110, alignment: .leading)
                                    }
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                            HStack {
                                Button("이전") { page -= 1 }.disabled(page == 0)
                                Button("다음") { page += 1 }.disabled(!result.hasNext)
                            }
                        }
                        .matchingPanel()
                    }
                }
            }
            .sheet(isPresented: $creating) {
                MatchingDraftComposer(service: service, gisuId: gisuId,
                                      canCreateOwn: canCreateOwn, canChooseOther: canChooseOther) { id in
                    creating = false
                    projectStatusValue = "DRAFT"
                    projectId = id
                }
            }
        }
    }

    private func projectStatus(_ raw: String) -> String {
        switch raw {
        case "DRAFT": "초안"
        case "PENDING_REVIEW": "검토 대기"
        case "IN_PROGRESS": "진행 중"
        case "ABORTED": "중단"
        case "COMPLETED": "완료"
        default: raw
        }
    }
}

struct OperationsLoad<Key: Equatable, Value: Sendable, Content: View>: View {
    let key: Key
    let load: @MainActor () async throws -> Value
    @ViewBuilder let content: (Value) -> Content
    @State private var value: Value?
    @State private var loadedKey: Key?
    @State private var failure: String?
    @State private var attempt = 0

    var body: some View {
        Group {
            if loadedKey == key, let value {
                content(value)
            } else if loadedKey == key, let failure {
                VStack(alignment: .leading) {
                    Label(failure, systemImage: "exclamationmark.circle")
                    Button("다시 시도") { attempt += 1 }
                }.matchingPanel()
            } else {
                ProgressView("불러오는 중")
                    .frame(maxWidth: .infinity, minHeight: 100)
            }
        }
        .task(id: Request(key: key, attempt: attempt)) { await reload() }
    }

    private struct Request: Equatable {
        let key: Key
        let attempt: Int
    }

    private func reload() async {
        let requestedKey = key
        value = nil
        failure = nil
        do {
            let response = try await load()
            try Task.checkCancellation()
            value = response
            loadedKey = requestedKey
        } catch {
            guard !Task.isCancelled else { return }
            failure = error.localizedDescription
            loadedKey = requestedKey
        }
    }
}

extension OperationsPerson {
    var display: String {
        [nickname ?? name, schoolName].compactMap { $0 }.joined(separator: " · ")
    }
}

enum OperationsPart {
    static let selectable = ["DESIGN", "WEB_PRODUCT_ENGINEER", "MOBILE_PRODUCT_ENGINEER"]
    static func phase(_ raw: String) -> String {
        switch raw {
        case "FIRST": "1차"
        case "SECOND": "2차"
        case "THIRD": "3차"
        case "RANDOM_MATCHING": "랜덤"
        default: raw
        }
    }
}
