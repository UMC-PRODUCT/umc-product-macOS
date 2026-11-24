//
//  MatchingStatisticsView.swift
//  MatchingPresentation
//
//  Created by euijjang97 on 11/22/26.
//

import CoreDesignSystem
import MatchingDomain
import SwiftUI

struct MatchingStatisticsView: View {
    let service: any MatchingUseCase
    let chapterId: String?
    let canReadAdjustment: Bool
    @State private var rosterType = MatchingRosterType.all
    @State private var adjustment = false
    @State private var revision = 0
    @State private var selectedId: String?
    @State private var request: ProjectConfirmation?
    @State private var sending = false
    @State private var failure: String?

    var body: some View {
        if let chapterId {
            VStack(alignment: .leading, spacing: UMCSpacing.value16) {
                Text("매칭 현황").umcTypography(.title1Bold)
                OperationsLoad(key: chapterId, load: {
                    try await service.publicStatistics(chapterId: chapterId)
                }) { stats in
                    Text("지부 기준 차수의 공개 통계").umcTypography(.title3Bold)
                    if !stats.roundMatchingStatistics.isEmpty {
                        LazyVGrid(columns: [.init(.adaptive(minimum: 180))], alignment: .leading) {
                            ForEach(stats.roundMatchingStatistics, id: \.phase) { phase in
                                VStack(alignment: .leading, spacing: UMCSpacing.value8) {
                                    Text(OperationsPart.phase(phase.phase)).umcTypography(.headlineBold)
                                    Text("매칭 완료 " + phase.matchedMemberCount + "명").umcTypography(.title2Bold)
                                    Text("매칭 대상 " + phase.availableMemberCount + "명")
                                }.matchingPanel(UMCColor.Semantic.surfaceBrandWeak)
                            }
                        }
                    }
                    DisclosureGroup("프로젝트별 공개 매칭 인원") {
                        ForEach(stats.projectMatchingStatistics, id: \.projectId) { project in
                            VStack(alignment: .leading, spacing: UMCSpacing.value8) {
                                LabeledContent(project.projectName, value: project.matchedMemberCount + " / " + project.quota)
                                HStack {
                                    ForEach(project.rounds, id: \.phase) { round in
                                        MatchingBadge(text: OperationsPart.phase(round.phase) + " · " + round.matchedMemberCount + "명")
                                    }
                                }
                                ForEach(project.parts, id: \.part) { part in
                                    LabeledContent(MatchingLabel.part(part.part), value: part.matchedMemberCount + " / " + part.quota)
                                }
                            }
                            Divider()
                        }
                    }.matchingPanel()
                    DisclosureGroup("학교별 공개 매칭 인원") {
                        ForEach(stats.schoolMatchingStatistics, id: \.schoolId) { school in
                            LabeledContent(school.schoolName, value: school.matchedMemberCount + " / " + school.totalMemberCount)
                        }
                    }.matchingPanel()
                }
                Picker("명단 매칭 유형", selection: $rosterType) {
                    Text("전체 파트").tag(MatchingRosterType.all)
                    Text("기획–디자인").tag(MatchingRosterType.design)
                    Text("기획–개발자").tag(MatchingRosterType.developer)
                }.frame(maxWidth: 300)
                if canReadAdjustment {
                    Picker("명단", selection: $adjustment) {
                        Text("공개 명단").tag(false)
                        Text("조정 명단").tag(true)
                    }.pickerStyle(.segmented).frame(maxWidth: 260)
                }
                let showsAdjustment = canReadAdjustment && adjustment
                OperationsLoad(key: [chapterId, String(showsAdjustment), String(revision)], load: {
                    try await service.overview(chapterId: chapterId, adjustment: showsAdjustment)
                }) { projects in
                    if projects.isEmpty {
                        ContentUnavailableView("표시할 프로젝트가 없어요", systemImage: "person.3")
                    } else {
                        VStack(alignment: .leading, spacing: UMCSpacing.value16) {
                            ForEach(projects, id: \.projectId) { project in
                                VStack(alignment: .leading, spacing: UMCSpacing.value8) {
                                    HStack {
                                        Text(project.projectName).umcTypography(.title3Bold)
                                        if let owner = project.productOwner { Text("PM · " + owner.display) }
                                        Spacer()
                                        Text("전체 " + project.currentMemberCount + " / " + project.quota)
                                        if let status = project.partQuotaStatus { MatchingBadge(text: MatchingLabel.status(status)) }
                                    }
                                    if !project.coProductOwners.isEmpty {
                                        Text("보조 PM · " + project.coProductOwners.map(\.display).joined(separator: ", "))
                                    }
                                    ForEach(project.parts.filter { rosterType.includes(part: $0.part) }, id: \.part) { part in
                                        LabeledContent(MatchingLabel.part(part.part) + " · " + part.currentMemberCount + " / " + part.quota, value: part.members.map { member in
                                            guard let phase = member.matchedRoundInfo?.phase else { return member.display }
                                            return member.display + " · " + OperationsPart.phase(phase)
                                        }.joined(separator: ", "))
                                    }
                                    if canReadAdjustment {
                                        Button(selectedId == project.projectId ? "닫기" : "배정 관리") {
                                        selectedId = selectedId == project.projectId ? nil : project.projectId
                                    }
                                    }
                                    if canReadAdjustment, selectedId == project.projectId {
                                        OperationsLoad(key: project.projectId, load: {
                                            try await service.permissions(projectId: project.projectId)
                                        }) { flags in
                                            AssignmentControls(service: service, project: project, permissions: flags, rosterType: rosterType) {
                                                request = $0
                                            }
                                        }
                                    }
                                }.matchingPanel()
                            }
                        }
                    }
                }
            }
            .onChange(of: rosterType) { _, _ in selectedId = nil }
            .onChange(of: adjustment) { _, _ in selectedId = nil }
            .disabled(sending)
            .alert(item: $request) { item in
                Alert(title: Text(item.title), message: Text(item.message),
                      primaryButton: .default(Text("확인")) {
                        guard !sending, let id = selectedId else { return }
                        sending = true
                        Task {
                            defer { sending = false }
                            do {
                                try await service.perform(item.operation, projectId: id)
                                revision += 1
                            } catch { failure = error.localizedDescription }
                        }
                      }, secondaryButton: .cancel(Text("취소")))
            }
            .alert("배정을 변경할 수 없어요", isPresented: .init(
                get: { failure != nil }, set: { if !$0 { failure = nil } }
            )) { Button("확인") { failure = nil } } message: { Text(failure ?? "") }
        } else {
            ContentUnavailableView("매칭 지부를 선택하세요", systemImage: "building.2")
        }
    }
}

private struct AssignmentControls: View {
    let service: any MatchingUseCase
    let project: OverviewProject
    let permissions: [ProjectPermission: MatchingCapability]
    let rosterType: MatchingRosterType
    let confirm: (ProjectConfirmation) -> Void
    @State private var selectedPart: String?
    private var parts: [String] {
        Array(Set(project.parts.map(\.part) + OperationsPart.selectable))
            .filter { rosterType.includes(part: $0) }.sorted()
    }
    private var part: String { selectedPart ?? parts.first ?? "" }
    @State private var page = 0

    var body: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value12) {
            if permissions[.assign]?.allowed == true {
                Picker("배정할 파트", selection: Binding(get: { part }, set: { selectedPart = $0 })) {
                    ForEach(parts, id: \.self) {
                        Text(MatchingLabel.part($0)).tag($0)
                    }
                }.onChange(of: part) { _, _ in page = 0 }
                OperationsLoad(key: [project.projectId, part, String(page)], load: {
                    try await service.candidates(projectId: project.projectId, part: part, page: page)
                }) { result in
                    if result.people.isEmpty { Text("배정 가능한 후보가 없어요.") }
                    ForEach(result.people, id: \.memberId) { person in
                        HStack {
                            Text(person.display)
                            Button("배정") {
                                confirm(.init(title: "팀원을 배정할까요?",
                                              message: project.projectName + " · " + person.display,
                                              operation: .assign(memberId: person.memberId, part: part)))
                            }
                        }
                    }
                    HStack {
                        Button("이전") { page -= 1 }.disabled(page == 0)
                        Button("다음") { page += 1 }.disabled(!result.hasNext)
                    }
                }
            }
            if permissions[.unassign]?.allowed == true {
                Menu("배정 해제") {
                    ForEach(project.parts.filter { rosterType.includes(part: $0.part) }, id: \.part) { group in
                        ForEach(group.members, id: \.memberId) { person in
                            Button(person.display) {
                                confirm(.init(title: "배정을 해제할까요?", message: project.projectName + " · " + person.display,
                                              operation: .unassign(memberId: person.memberId)))
                            }
                        }
                    }
                }.disabled(project.parts.filter { rosterType.includes(part: $0.part) }.allSatisfy { $0.members.isEmpty })
            }
            if permissions[.assign]?.allowed != true && permissions[.unassign]?.allowed != true {
                Text(permissions[.assign]?.reason ?? "현재 배정을 변경할 수 없어요.").foregroundStyle(.secondary)
            }
        }
    }
}
