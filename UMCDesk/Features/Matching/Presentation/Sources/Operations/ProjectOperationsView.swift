//
//  ProjectOperationsView.swift
//  MatchingPresentation
//
//  Created by euijjang97 on 11/22/26.
//

import CoreDesignSystem
import CoreUIComponents
import MatchingDomain
import SwiftUI
import UniformTypeIdentifiers

private enum ProjectPage: String, CaseIterable {
    case posting = "공고 편집"
    case form = "지원 폼"
    case review = "지원자 심사"
    case team = "팀 구성"
    case statistics = "지원 통계"
    case state = "상태 관리"
}

struct ProjectOperationsView<Header: View>: View {
    let service: any MatchingUseCase
    let projectId: String
    var status: String?
    @ViewBuilder let header: () -> Header
    let close: () -> Void
    @State private var details = MatchingRequest<(MatchingProject, [ProjectPermission: MatchingCapability])>()
    @State private var page = ProjectPage.posting
    @State private var inspectingDraft = false
    @State private var revision = 0
    @State private var pending: ProjectConfirmation?
    @State private var operationTask: Task<Void, Never>?
    @State private var busy = false
    @State private var failure: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: UMCSpacing.value16) {
                Text("내 프로젝트").umcTypography(.largeTitle3Bold)
                    .accessibilityAddTraits(.isHeader)
                header()
                Divider()
                Button("관리 프로젝트", systemImage: "chevron.left", action: close)
                MatchingRequestView(request: details, retry: { revision += 1 }) { project, permissions in
                    let context = ProjectContext(project: project, status: status, permissions: permissions,
                                                 service: service, confirm: { pending = $0 })
                    if status == "PENDING_REVIEW", inspectingDraft || page != .posting {
                        Button("공개 검토로", systemImage: "chevron.left") {
                            inspectingDraft = false
                            page = .posting
                        }
                    }
                    Text(project.name).umcTypography(.title1Bold)
                    Picker("관리 도구", selection: $page) {
                        ForEach(ProjectPage.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }.pickerStyle(.segmented)
                    switch page {
                    case .posting where status == "PENDING_REVIEW" && !inspectingDraft:
                        ProjectPublicationReview(
                            context: context,
                            inspectPosting: { inspectingDraft = true },
                            inspectForm: { page = .form }
                        )
                    case .posting: ProjectPostingEditor(context: context)
                    case .state: ProjectStatusEditor(context: context)
                    case .form:
                        if context.allows(.formRead) || context.allows(.formCreate) {
                            OperationsLoad(key: project.id, load: {
                                if project.applicationFormId == nil {
                                    return EditableMatchingForm(title: nil, description: nil, sections: [])
                                }
                                return try await service.editableForm(projectId: projectId)
                            }) { MatchingFormEditor(context: context, form: $0) }
                        } else { context.restricted(.formRead) }
                    case .review:
                        if context.allows(.applicants) { ProjectReviewView(context: context) }
                        else { context.restricted(.applicants) }
                    case .team:
                        if context.allows(.team) { ProjectTeamView(context: context) }
                        else { context.restricted(.team) }
                    case .statistics:
                        if context.allows(.statistics) {
                            OperationsLoad(key: project.id, load: {
                                try await service.applicationStatistics(projectId: projectId)
                            }) { stats in
                                VStack(alignment: .leading, spacing: UMCSpacing.value16) {
                                    if let type = stats.matchingType {
                                        MatchingBadge(text: type == "PLAN_DESIGN" ? "기획–디자인" :
                                                    type == "PLAN_DEVELOPER" ? "기획–개발자" : type)
                                    }
                                    Text("학교별 지원 현황").umcTypography(.title3Bold)
                                    ForEach(stats.schoolApplicationStatistics, id: \.schoolId) { school in
                                        Text(school.schoolName + " · 대상 " + school.totalMemberCount + "명")
                                        phaseCounts(school.rounds)
                                    }
                                    Divider()
                                    Text("프로젝트별 지원 현황").umcTypography(.title3Bold)
                                    ForEach(stats.projectRoundStatistics, id: \.projectId) { project in
                                        Text(project.projectName)
                                        phaseCounts(project.rounds)
                                    }
                                }.matchingPanel()
                            }
                        } else { context.restricted(.statistics) }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(UMCSpacing.value24)
        }
        .umcTabTools("매칭 도구", width: .wide) { dismiss in
            if case .loaded(let (project, flags)) = details.phase, project.id == projectId {
                ownerTools(flags: flags, dismiss: dismiss)
            }
            UMCToolGroupHeading("프로젝트 관리")
            Button("관리 프로젝트 목록", systemImage: "folder") {
                dismiss()
                close()
            }
            if case .loaded(let (project, flags)) = details.phase, project.id == projectId {
                if flags[.team]?.allowed == true, flags[.transfer]?.allowed == true {
                    pageButton("소유권 양도", .team, dismiss)
                }
                if [.complete, .abort, .delete].contains(where: { flags[$0]?.allowed == true }) {
                    pageButton("프로젝트 상태 관리", .state, dismiss)
                }
            }
        }
        .task(id: revision) {
            await details.load {
                async let project = service.project(id: projectId)
                async let permissions = service.permissions(projectId: projectId)
                return try await (project, permissions)
            }
        }
        .onDisappear { operationTask?.cancel() }
        .disabled(busy)
        .overlay { if busy { ProgressView("저장 중") } }
        .alert(item: $pending) { request in
            Alert(title: Text(request.title), message: Text(request.message),
                  primaryButton: .default(Text("확인")) { perform(request.operation) },
                  secondaryButton: .cancel(Text("취소")))
        }
        .alert("요청을 처리할 수 없어요", isPresented: .init(
            get: { failure != nil }, set: { if !$0 { failure = nil } }
        )) { Button("확인") { failure = nil } } message: { Text(failure ?? "") }
    }

    @ViewBuilder private func ownerTools(flags: [ProjectPermission: MatchingCapability],
                                         dismiss: @escaping () -> Void) -> some View {
        let canForm = flags[.formRead]?.allowed == true || flags[.formCreate]?.allowed == true
        let canReview = flags[.publish]?.allowed == true || flags[.quota]?.allowed == true
        if flags[.edit]?.allowed == true {
            Button("프로젝트 공고 편집", systemImage: "pencil") {
                dismiss()
                inspectingDraft = true
                page = .posting
            }.buttonStyle(UMCToolPrimaryButtonStyle())
            Divider()
        }
        if canForm || canReview {
            UMCToolGroupHeading("모집 준비")
            if canForm { pageButton("지원 폼", .form, dismiss) }
            if canReview {
                pageButton(status == "PENDING_REVIEW" ? "공개 검토 · 파트 정원" : "파트 정원",
                           .posting, dismiss)
            }
            Divider()
        }
        if [.applicants, .team, .statistics].contains(where: { flags[$0]?.allowed == true }) {
            UMCToolGroupHeading("선발과 팀")
            if flags[.applicants]?.allowed == true { pageButton("지원자 심사", .review, dismiss) }
            if flags[.team]?.allowed == true { pageButton("팀 구성 · 팀원 관리", .team, dismiss) }
            if flags[.statistics]?.allowed == true { pageButton("지원 통계", .statistics, dismiss) }
            Divider()
        }
    }

    private func pageButton(_ title: String, _ target: ProjectPage,
                            _ dismiss: @escaping () -> Void) -> some View {
        Button(title) {
            dismiss()
            inspectingDraft = false
            page = target
        }
    }

    private func phaseCounts(_ rows: [ApplicationPhaseCount]) -> some View {
        HStack {
            ForEach(rows, id: \.phase) { row in
                MatchingBadge(text: OperationsPart.phase(row.phase) + " · " + row.applicantCount + "명")
            }
        }
    }

    private func perform(_ operation: ProjectOperation) {
        guard !busy else { return }
        busy = true
        operationTask = Task {
            defer { busy = false }
            do {
                try await service.perform(operation, projectId: projectId)
                try Task.checkCancellation()
                switch operation {
                case .submit, .publish, .delete, .abort, .complete:
                    close()
                default:
                    revision += 1
                }
            } catch is CancellationError {
                return
            } catch let MatchingFormSaveError.answeredSectionDeletion(message) {
                if case let .form(form, false) = operation {
                    pending = .init(title: "제출된 답변까지 삭제할까요?", message: message,
                                    operation: .form(form, confirmDeletion: true))
                } else { failure = message }
            } catch { failure = error.localizedDescription }
        }
    }
}

struct ProjectConfirmation: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let operation: ProjectOperation
}

struct ProjectContext {
    let project: MatchingProject
    let status: String?
    let permissions: [ProjectPermission: MatchingCapability]
    let service: any MatchingUseCase
    let confirm: (ProjectConfirmation) -> Void

    func allows(_ action: ProjectPermission) -> Bool { permissions[action]?.allowed == true }

    func restricted(_ action: ProjectPermission) -> some View {
        ContentUnavailableView("접근이 제한됐어요", systemImage: "lock",
                               description: Text(permissions[action]?.reason ?? "이 작업을 사용할 권한이 없어요."))
    }

    func request(_ title: String, _ message: String, _ operation: ProjectOperation) {
        confirm(.init(title: title, message: message, operation: operation))
    }
}

private struct ProjectPostingEditor: View {
    let context: ProjectContext
    @State private var name: String
    @State private var summary: String
    @State private var link: String
    @State private var choosingImage = false
    @State private var slot = ProjectImageSlot.thumbnail

    init(context: ProjectContext) {
        self.context = context
        _name = State(initialValue: context.project.name)
        _summary = State(initialValue: context.project.description ?? "")
        _link = State(initialValue: context.project.externalLink ?? "")
    }

    var body: some View {
        HStack(alignment: .top, spacing: UMCSpacing.value16) {
            VStack(alignment: .leading, spacing: UMCSpacing.value12) {
                Text("프로젝트 공고").umcTypography(.title3Bold)
                TextField("프로젝트 이름", text: $name)
                    .umcInputField()
                TextField("소개", text: $summary, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                TextField("외부 소개 링크", text: $link)
                    .umcInputField()
                if context.allows(.edit) {
                    HStack {
                        Button("썸네일 변경") { slot = .thumbnail; choosingImage = true }
                        Button("로고 변경") { slot = .logo; choosingImage = true }
                    }
                }
                Button("공고 저장") {
                    context.request("공고를 저장할까요?", name,
                                    .edit(name: name, description: summary, link: link))
                }
                .disabled(!context.allows(.edit) || name.isEmpty || name.count > 100 ||
                          summary.count > 200 || link.count > 300 ||
                          (!link.isEmpty && MatchingLabel.webURL(link) == nil))
                if context.allows(.submit) {
                    Button("검토 요청") {
                        context.request("공고 검토를 요청할까요?", name, .submit)
                    }
                }
            }
            .fileImporter(isPresented: $choosingImage,
                          allowedContentTypes: slot == .thumbnail ? [.jpeg, .png] : [.jpeg, .png, .svg]) { choice in
                guard case let .success(file) = choice else { return }
                context.request(slot == .thumbnail ? "썸네일을 변경할까요?" : "로고를 변경할까요?",
                                file.lastPathComponent, .changeImage(file: file, slot: slot))
            }
            .matchingPanel()
            ProjectQuotaPanel(context: context, isPublicationReview: false)
        }
    }
}

extension MatchingProject {
    var hasConfiguredQuota: Bool { partQuotas.contains { (Int($0.quota) ?? 0) > 0 } }
    var isReadyForPublication: Bool { applicationFormId != nil && hasConfiguredQuota }
}

private struct ProjectPublicationReview: View {
    let context: ProjectContext
    let inspectPosting: () -> Void
    let inspectForm: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value24) {
            HStack {
                VStack(alignment: .leading, spacing: UMCSpacing.value8) {
                    Text("프로젝트 공개 검토").umcTypography(.largeTitle3Bold)
                    Text("공고 · 지원 폼 · 파트 정원을 확인한 뒤 모집을 시작하세요.")
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("초안으로", action: inspectPosting)
                    .buttonStyle(MatchingActionStyle(appearance: .text))
                    .help("공고 편집 화면으로 이동")
                Button("공고 공개") {
                    context.request("공고를 공개할까요?", "지원 폼도 함께 공개됩니다.", .publish)
                }
                .buttonStyle(MatchingActionStyle(appearance: .primary))
                .disabled(!context.allows(.publish) || !context.project.isReadyForPublication)
            }
            HStack(alignment: .top, spacing: UMCSpacing.value24) {
                VStack(alignment: .leading, spacing: UMCSpacing.value16) {
                    MatchingBadge(text: "검토 대기")
                    Text(context.project.name).umcTypography(.title1Bold)
                    if let pm = context.project.productOwner {
                        Text([pm.nickname ?? pm.name, pm.schoolName].compactMap { $0 }
                            .joined(separator: " · ")).foregroundStyle(.secondary)
                    }
                    if let description = context.project.description { Text(description) }
                    Divider()
                    HStack {
                        if let url = MatchingLabel.webURL(context.project.externalLink) {
                            Link("소개 자료", destination: url)
                        }
                        Button("지원 폼 확인", action: inspectForm)
                            .buttonStyle(MatchingActionStyle(appearance: .secondary))
                            .disabled(context.project.applicationFormId == nil ||
                                      !context.allows(.formRead))
                    }
                    if context.project.applicationFormId == nil {
                        Text("지원 폼 미등록")
                    } else if context.allows(.formRead) {
                        OperationsLoad(key: context.project.id, load: {
                            try await context.service.editableForm(projectId: context.project.id)
                        }) { form in
                            let common = questionCount("COMMON", in: form)
                            let part = questionCount("PART", in: form)
                            Text("공통 질문 \(common)개 · 파트 질문 \(part)개")
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text("지원 폼 등록됨").foregroundStyle(.secondary)
                    }
                }.matchingPanel()
                ProjectQuotaPanel(context: context, isPublicationReview: true)
            }
        }
    }

    private func questionCount(_ type: String, in form: EditableMatchingForm) -> Int {
        form.sections.filter { $0.type == type }.reduce(0) { $0 + $1.questions.count }
    }
}

private struct ProjectQuotaPanel: View {
    let context: ProjectContext
    let isPublicationReview: Bool
    @State private var quotas: [String: Int]

    init(context: ProjectContext, isPublicationReview: Bool) {
        self.context = context
        self.isPublicationReview = isPublicationReview
        _quotas = State(initialValue: Dictionary(uniqueKeysWithValues: context.project.partQuotas.compactMap {
            guard let quota = Int($0.quota) else { return nil }
            return ($0.part, quota)
        }))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value12) {
            Text("파트별 모집 정원").umcTypography(.title3Bold)
            ForEach(Array(Set(OperationsPart.selectable + quotas.keys)).sorted(), id: \.self) { part in
                Stepper(value: Binding(get: { quotas[part] ?? 0 }, set: { quotas[part] = $0 }),
                        in: 0...999) {
                    Text(MatchingLabel.part(part) + " · " + String(quotas[part] ?? 0))
                }
                .disabled(!context.allows(.quota))
            }
            if context.allows(.quota) {
                Button("정원 저장") {
                    let openings = quotas.filter { $0.value > 0 }
                    context.request("모집 정원을 저장할까요?", context.project.name, .quotas(openings))
                }.disabled(!quotas.values.contains { $0 > 0 })
            }
            if isPublicationReview {
                let registered = context.project.applicationFormId != nil
                let configured = context.project.hasConfiguredQuota
                VStack(alignment: .leading, spacing: UMCSpacing.value8) {
                    Text(context.project.isReadyForPublication ? "공개 준비 완료" : "공개 준비 중")
                        .umcTypography(.headlineBold)
                    Text((registered ? "지원 폼 등록됨" : "지원 폼 미등록") + " · " +
                         (configured ? "모집 정원 설정됨" : "모집 정원 미설정"))
                }.matchingPanel(UMCColor.Semantic.surfaceBrandMedium)
                if !context.allows(.publish), let reason = context.permissions[.publish]?.reason {
                    Text(reason).foregroundStyle(.secondary)
                }
            } else if context.allows(.publish) {
                Button("프로젝트 공개") { context.request("프로젝트를 공개할까요?", context.project.name, .publish) }
            }
        }.matchingPanel()
    }
}

private struct ProjectStatusEditor: View {
    let context: ProjectContext
    @State private var reason = ""

    var body: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value16) {
            if context.allows(.complete) {
                Button("프로젝트 완료") {
                    context.request("프로젝트를 완료할까요?", "활동 중인 팀원은 활동 완료로, 작성·제출 중인 지원서는 취소로 바뀝니다.", .complete)
                }
            }
            if context.allows(.abort) {
                TextField("중단 사유 · 최대 255자", text: $reason)
                    .umcInputField()
                Button("프로젝트 중단", role: .destructive) {
                    context.request("프로젝트를 중단할까요?", reason, .abort(reason: reason))
                }.disabled(reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || reason.count > 255)
            }
            if context.allows(.delete) {
                Button("프로젝트 삭제", role: .destructive) {
                    context.request("프로젝트를 삭제할까요?", "지원 폼, 정원과 팀원 정보가 함께 삭제됩니다.", .delete)
                }
            }
            if ![ProjectPermission.complete, .abort, .delete].contains(where: context.allows) {
                context.restricted(.complete)
            }
        }.matchingPanel()
    }
}
