//
//  MatchingApplications.swift
//  MatchingPresentation
//
//  Created by euijjang97 on 11/22/26.
//

import CoreDesignSystem
import MatchingDomain
import SwiftUI
import UniformTypeIdentifiers

struct MatchingApplications: View {
    let repository: any MatchingUseCase
    let gisuId: String
    let memberId: String?
    let rounds: [MatchingRound]
    let onOpenProject: ((String) -> Void)?
    let explore: () -> Void
    @State private var request = MatchingRequest<[MatchingApplication]>()
    @State private var attempt = 0
    @State private var route: MatchingApplicationRoute?

    @State private var additionalRounds: [MatchingRound] = []
    @State private var resultsOnly = false
    @State private var withdrawal: MatchingApplicationRoute?
    @State private var withdrawing = false
    @State private var actionError: String?
    @State private var writeTask: Task<Void, Never>?

    var body: some View {
        MatchingRequestView(request: request, retry: { attempt += 1 }) { records in
            if records.isEmpty {
                ContentUnavailableView {
                    Label("아직 지원한 프로젝트가 없어요", systemImage: "doc.text")
                } actions: { Button("프로젝트 둘러보기", action: explore) }
            } else {
                let results = records.filter { $0.status == "APPROVED" || $0.status == "REJECTED" }
                let visible = resultsOnly ? results : records
                let singleApproved = visible.lazy.filter { $0.status == "APPROVED" }.prefix(2).count == 1
                MatchingColumns {
                    VStack(alignment: .leading, spacing: UMCSpacing.value24) {
                        ForEach(visible.filter { $0.status != "DRAFT" }, id: \.cardId) { card in
                            applicationCard(card, teamShortcut: singleApproved)
                        }
                        let drafts = visible.filter { $0.status == "DRAFT" }
                        if !drafts.isEmpty {
                            VStack(alignment: .leading, spacing: UMCSpacing.value16) {
                                Text("작성 중인 지원서").umcTypography(.title3Bold)
                                ForEach(drafts, id: \.cardId) { card in applicationCard(card) }
                            }.matchingPanel()
                        }
                        if visible.isEmpty {
                            Text("아직 공개된 매칭 결과가 없어요.").foregroundStyle(.secondary)
                        }
                    }.matchingPanel()
                    VStack(alignment: .leading, spacing: UMCSpacing.value24) {
                        if visible.contains(where: { $0.status == "APPROVED" }) {
                            Text("매칭 결과와 팀 구성").umcTypography(.largeTitle3Bold)
                            Text("합격한 프로젝트의 공개 팀 명단에서 내 합류 여부를 확인할 수 있어요.")
                        } else {
                            Text("한 차수, 한 번의 선택.").umcTypography(.largeTitle3Bold)
                            Text("여러 프로젝트의 초안을 작성할 수 있지만 같은 차수에는 하나의 지원서만 제출할 수 있어요.")
                            Divider()
                            Text("지원 기간에는 제출한 답변을 수정할 수 있어요. 철회 후 다시 지원할 수도 있어요.")
                        }
                        Button(resultsOnly ? "전체 지원 보기" : "지난 매칭 결과") { resultsOnly.toggle() }
                            .buttonStyle(MatchingActionStyle(appearance: .secondary))
                    }.matchingPanel()
                }
            }
        }
        .disabled(withdrawing)
        .task(id: attempt) {
            await request.load { try await repository.personalCards(gisuId: gisuId) }
            guard case .loaded(let cards) = request.phase else { return }
            let missing = Set(cards.compactMap { $0.matchingRound?.id }).subtracting(rounds.map(\.id))
            if !missing.isEmpty, let all = try? await repository.rounds(chapterId: nil),
               !Task.isCancelled {
                additionalRounds = all.filter { missing.contains($0.id) }
            }
        }
        .onDisappear { writeTask?.cancel() }
        .sheet(item: $route) { route in
            MatchingApplicationEditor(repository: repository, route: route, rounds: rounds + additionalRounds,
                                      onChange: { attempt += 1 })
        }
        .alert(item: $withdrawal) { item in
            Alert(title: Text("\(item.projectName) 지원을 철회할까요?"),
                  message: Text("철회하면 이 차수의 지원이 취소돼요. 지원 기간 안에는 다시 지원할 수 있어요."),
                  primaryButton: .destructive(Text("지원 철회")) {
                      guard !withdrawing else { return }
                      withdrawing = true
                      writeTask = Task {
                          defer { withdrawing = false }
                          do {
                              try await repository.cancelApplication(projectId: item.projectId,
                                                                     applicationId: item.id)
                              try Task.checkCancellation()
                              attempt += 1
                          } catch { if !Task.isCancelled { actionError = error.localizedDescription } }
                      }
                  }, secondaryButton: .cancel(Text("취소")))
        }
        .alert("지원을 철회할 수 없어요", isPresented: Binding(
            get: { actionError != nil }, set: { if !$0 { actionError = nil } }
        )) { Button("확인") { actionError = nil } } message: { Text(actionError ?? "") }
    }

    private func applicationCard(
        _ card: MatchingApplication, teamShortcut: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value16) {
            if card.status == "APPROVED", let memberId {
                MatchingAssignmentResult(
                    repository: repository, card: card, memberId: memberId,
                    onOpenProject: onOpenProject, teamShortcut: teamShortcut
                )
                .id(card.projectId)
            }
            HStack {
                VStack(alignment: .leading, spacing: UMCSpacing.value4) {
                    Text(card.project?.name ?? "프로젝트").umcTypography(.title3Bold)
                    if let round = card.matchingRound {
                        Text(roundLabel(round)).umcTypography(.bodyRegular).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                MatchingBadge(text: MatchingLabel.status(card.status))
            }
            if let applicationId = card.applicationId {
                let item = MatchingApplicationRoute(id: applicationId, projectId: card.projectId,
                    projectName: card.project?.name ?? "프로젝트", roundId: card.matchingRound?.id,
                    isDraft: card.status == "DRAFT")
                MatchingPersonalActions(repository: repository, card: card, route: item,
                    knownRound: (rounds + additionalRounds).first { $0.id == item.roundId }, open: { route = item },
                    withdraw: { withdrawal = item })
            } else {
                Label(card.matchingRound?.phase == "RANDOM_MATCHING"
                      ? "랜덤 매칭 차수 배정" : "팀 배정", systemImage: "person.2.fill")
            }
        }
    }

    private func roundLabel(_ brief: MatchingRoundBrief) -> String {
        if let value = (rounds + additionalRounds).first(where: { $0.id == brief.id }) { return value.name }
        let name = brief.type == "PLAN_DESIGN" ? "기획–디자인" :
            (brief.type == "PLAN_DEVELOPER" ? "기획–개발자" : "")
        let phase = ["FIRST": "1차", "SECOND": "2차", "THIRD": "3차", "RANDOM_MATCHING": "랜덤 매칭"]
        return [name, phase[brief.phase ?? ""] ?? brief.phase ?? ""]
            .filter { !$0.isEmpty }.joined(separator: " ")
    }
}

private struct MatchingPersonalActions: View {
    let repository: any MatchingUseCase
    let card: MatchingApplication
    let route: MatchingApplicationRoute
    let knownRound: MatchingRound?
    let open: () -> Void
    let withdraw: () -> Void
    @State private var submittedAt: String?
    @State private var lastSavedAt: String?

    var body: some View {
        let round = knownRound
        VStack(alignment: .leading, spacing: UMCSpacing.value16) {
            if card.status == nil || card.status == "SUBMITTED" {
                HStack(alignment: .top, spacing: UMCSpacing.value16) {
                    stage("작성 완료", date: nil, complete: true)
                    stage("제출 완료", date: submittedAt, complete: true)
                    stage("결과 공개 예정", date: round?.resultPublishAt, complete: false)
                }
                VStack(alignment: .leading, spacing: UMCSpacing.value8) {
                    Text("지원서가 전달됐어요").umcTypography(.headlineBold)
                    let dates = [
                        round?.decisionDeadline.map { "판정 마감 " + MatchingLabel.time($0) },
                        round?.resultPublishAt.map { "공개 " + MatchingLabel.time($0) + " 예정" }
                    ].compactMap { $0 }.joined(separator: " · ")
                    if !dates.isEmpty { Text(dates).umcTypography(.bodyRegular) }
                    Text("발표 완료 후 결과를 확인해 주세요.").umcTypography(.bodyRegular)
                }.matchingPanel(UMCColor.Semantic.surfaceBrandMedium)
            }
            if route.isDraft, let saved = lastSavedAt {
                Text("마지막 저장 · " + MatchingLabel.time(saved)).umcTypography(.bodyRegular)
            }
            HStack {
                Button(route.isDraft ? "이어서 작성" : "제출한 내용 보기", action: open)
                    .buttonStyle(MatchingActionStyle(appearance: route.isDraft ? .primary : .text))
                if card.status == nil || card.status == "SUBMITTED" || route.isDraft {
                    TimelineView(.periodic(from: .now, by: 10)) { tick in
                        if round?.isOpen(at: tick.date) == true {
                            Button("지원 철회", role: .destructive, action: withdraw)
                                .buttonStyle(.plain)
                                .foregroundStyle(UMCColor.Semantic.textError)
                        }
                    }
                }
            }
        }
        .task(id: route.id) {
            guard route.isDraft || card.status == nil || card.status == "SUBMITTED" else { return }
            let detail = try? await repository.application(projectId: route.projectId, applicationId: route.id)
            guard !Task.isCancelled else { return }
            submittedAt = detail?.submittedAt
            lastSavedAt = detail?.formResponse?.lastSavedAt
        }
    }

    private func stage(_ title: String, date: String?, complete: Bool) -> some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value8) {
            Text(title).umcTypography(.bodyRegular)
            Text(date.map { MatchingLabel.time($0) } ?? " ")
                .umcTypography(.bodyRegular)
                .accessibilityHidden(date == nil)
            Capsule()
                .fill(complete ? UMCColor.Semantic.fillPrimaryInverseStrong500
                               : UMCColor.Semantic.surfaceNeutralMedium)
                .frame(height: 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

private struct MatchingAssignmentResult: View {
    let repository: any MatchingUseCase
    let card: MatchingApplication
    let memberId: String
    let onOpenProject: ((String) -> Void)?
    let teamShortcut: Bool
    @State private var request = MatchingRequest<OperationsTeam?>()
    @State private var attempt = 0
    @State private var showingTeam = false
    @FocusState private var teamButtonFocused: Bool

    var body: some View {
        MatchingRequestView(request: request, retry: { attempt += 1 }) { roster in
            if let roster {
                VStack(alignment: .leading, spacing: UMCSpacing.value16) {
                    if let member = roster.publishedMember(withID: memberId) {
                        MatchingBadge(text: onOpenProject == nil
                                      ? "합류 확인" : "합류 확인 · 작업 공간 연결됨")
                        Text((card.project?.name ?? "프로젝트") + "에 합류했어요!")
                            .umcTypography(.largeTitle3Bold)
                            .accessibilityAddTraits(.isHeader)
                        Text([member.person.nickname ?? member.person.name, member.role]
                            .compactMap { $0 }.joined(separator: " · "))
                            .umcTypography(.headlineBold)
                        if onOpenProject != nil {
                            Text("프로젝트 작업 공간을 열어 보세요.").foregroundStyle(.secondary)
                        }
                        HStack(spacing: UMCSpacing.value16) {
                            if let onOpenProject {
                                Button {
                                    onOpenProject(card.projectId)
                                } label: {
                                    HStack {
                                        Text("프로젝트 열기")
                                        Image(systemName: "arrow.right").accessibilityHidden(true)
                                    }.frame(maxWidth: .infinity)
                                }
                                .buttonStyle(MatchingActionStyle(appearance: .text))
                            }
                            teamButton
                        }
                    } else {
                        MatchingBadge(text: "합격 · 팀 등록 대기")
                        Label("현재 공개 팀 명단에 이름이 없어요", systemImage: "clock")
                        refreshResult
                        teamButton
                    }
                }
                .sheet(isPresented: $showingTeam, onDismiss: { teamButtonFocused = true }) {
                    MatchingTeamPanel { MatchingRosterList(team: roster) }
                }
            } else {
                VStack(alignment: .leading, spacing: UMCSpacing.value12) {
                    Text("공개 팀 명단을 확인할 수 없어요.").foregroundStyle(.secondary)
                    refreshResult
                }
            }
        }
        .task(id: attempt) {
            await request.load { try await repository.publishedTeam(projectId: card.projectId) }
        }
    }

    private var refreshResult: some View {
        Button("결과 새로고침") { attempt += 1 }
            .buttonStyle(MatchingActionStyle(appearance: .secondary))
    }

    private var teamButton: some View {
        Button { showingTeam = true } label: {
            Text("팀 구성 보기").frame(maxWidth: .infinity)
        }
        .buttonStyle(MatchingActionStyle(appearance: .text))
        .focused($teamButtonFocused)
        .keyboardShortcut(teamShortcut ? KeyboardShortcut("t", modifiers: .option) : nil)
        .help(teamShortcut ? "공개 팀 구성 보기 (⌥T)" : "공개 팀 구성 보기")
    }
}

extension OperationsTeam {
    func publishedMember(withID memberId: String) -> (person: OperationsPerson, role: String)? {
        guard !memberId.isEmpty else { return nil }
        if let owner = productOwner, owner.memberId == memberId { return (owner, "담당 PM") }
        if let coOwner = coProductOwners.first(where: { $0.memberId == memberId }) {
            return (coOwner, "보조 PM")
        }
        for group in partGroups {
            if let member = group.members.first(where: { $0.memberId == memberId }) {
                return (member, MatchingLabel.part(group.part))
            }
        }
        return nil
    }
}

extension MatchingApplication {
    var cardId: String { applicationId.map { "application-" + $0 } ?? "assigned-" + projectId }
}

@MainActor
@Observable
private final class MatchingApplicationEditorModel {
    let repository: any MatchingUseCase
    let route: MatchingApplicationRoute
    let detail = MatchingRequest<MatchingApplicationDetail>()
    var answers: [String: MatchingAnswer] = [:]
    var fileNames: [String: String] = [:]
    var archivedQuestions: Set<String> = []
    var round: MatchingRound?
    var editing: Bool
    var busy = false
    var failure: String?
    var saved = false

    init(repository: any MatchingUseCase, route: MatchingApplicationRoute) {
        self.repository = repository
        self.route = route
        editing = route.isDraft
    }

    func load(rounds: [MatchingRound]) async {
        await detail.load {
            let result = try await repository.application(projectId: route.projectId, applicationId: route.id)
            if let sections = result.formResponse?.sections {
                for question in sections.flatMap(\.questions) {
                    let saved = question.answer
                    let currentIds = Set(question.options.map(\.optionId))
                    if saved?.selectedOptions.contains(where: { item in
                        !currentIds.contains(item.questionOptionId ?? "")
                    }) == true {
                        archivedQuestions.insert(question.questionId)
                    }
                    answers[question.questionId] = MatchingAnswer(
                        questionId: question.questionId, textValue: saved?.textValue,
                        selectedOptionIds: saved?.selectedOptions.compactMap(\.questionOptionId) ?? [],
                        fileIds: saved?.files.map(\.fileId) ?? []
                    )
                    for file in saved?.files ?? [] { fileNames[file.fileId] = file.originalFileName ?? file.fileId }
                }
            }
            return result
        }
        if let roundId = route.roundId {
            round = rounds.first { $0.id == roundId }
            if round == nil {
                do { round = try await repository.rounds(chapterId: nil).first { $0.id == roundId } }
                catch { failure = error.localizedDescription }
            }
        }
    }

    func upload(file: URL, questionId: String) async {
        guard !busy else { return }
        busy = true
        defer { busy = false }
        do {
            let fileId = try await repository.uploadPortfolio(file: file)
            fileNames[fileId] = file.lastPathComponent
            answers[questionId, default: MatchingAnswer(questionId: questionId)].fileIds.append(fileId)
            failure = nil
        } catch { failure = error.localizedDescription }
    }

    func hasValue(_ question: MatchingQuestion) -> Bool {
        guard let answer = answers[question.questionId] else { return false }
        return !(answer.textValue?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
            || !answer.selectedOptionIds.isEmpty || !answer.fileIds.isEmpty
    }

    func persist(_ action: EditorAction, dismissed: () -> Void) async {
        guard !busy else { return }
        busy = true
        defer { busy = false }
        failure = nil
        do {
            guard action == .withdraw || archivedQuestions.isEmpty else {
                failure = "변경된 선택지의 기존 답변을 확인해 주세요."
                return
            }
            if action == .withdraw {
                try await repository.cancelApplication(projectId: route.projectId, applicationId: route.id)
            } else {
                let values = answers.values.filter {
                    !($0.textValue ?? "").isEmpty || !$0.selectedOptionIds.isEmpty || !$0.fileIds.isEmpty
                }
                try await repository.saveAnswers(projectId: route.projectId, applicationId: route.id,
                                                 answers: values.sorted { $0.questionId < $1.questionId })
                saved = true
                if action == .submit {
                    try Task.checkCancellation()
                    try await repository.submitApplication(projectId: route.projectId, applicationId: route.id)
                }
            }
            saved = true
            dismissed()
        } catch { failure = error.localizedDescription }
    }
}

private enum EditorAction: String, Identifiable {
    case save, submit, withdraw
    var id: Self { self }
}

struct MatchingApplicationEditor: View {
    @Environment(\.dismiss) private var dismiss
    @State private var model: MatchingApplicationEditorModel
    let rounds: [MatchingRound]
    let onChange: () -> Void
    @State private var attempt = 0
    @State private var confirmation: EditorAction?
    @State private var fileQuestion: String?
    @State private var importing = false
    @State private var writeTask: Task<Void, Never>?

    init(repository: any MatchingUseCase, route: MatchingApplicationRoute,
         rounds: [MatchingRound], onChange: @escaping () -> Void) {
        _model = State(initialValue: .init(repository: repository, route: route))
        self.rounds = rounds
        self.onChange = onChange
    }

    var body: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value16) {
            HStack {
                Text("\(model.route.projectName) 지원서").umcTypography(.largeTitle3Bold)
                Spacer()
                Button("닫기") { dismiss() }.keyboardShortcut(.cancelAction)
            }
            MatchingRequestView(request: model.detail, retry: { attempt += 1 }) { detail in
                if let sections = detail.formResponse?.sections {
                    HStack(alignment: .top, spacing: UMCSpacing.value20) {
                        sidebar(sections, detail: detail)
                        ScrollView {
                            VStack(alignment: .leading, spacing: UMCSpacing.value24) {
                                ForEach(sections, id: \.sectionId) { section in
                                    VStack(alignment: .leading, spacing: UMCSpacing.value12) {
                                        Text(section.title).umcTypography(.title3Bold)
                                        if let text = section.description { Text(text) }
                                        ForEach(section.questions, id: \.questionId) { question in
                                            field(question)
                                        }
                                    }
                                }
                            }.matchingPanel()
                        }
                    }
                    if let failure = model.failure { Text(failure).foregroundStyle(UMCColor.Semantic.textError) }
                    TimelineView(.periodic(from: .now, by: 10)) { tick in
                        actions(sections, detail: detail, now: tick.date)
                    }
                } else {
                    ContentUnavailableView("지원서 본문을 불러올 수 없어요", systemImage: "doc")
                }
            }
        }
        .disabled(model.busy)
        .interactiveDismissDisabled(model.busy)
        .padding(UMCSpacing.value24)
        .frame(minWidth: 720, idealWidth: 840, minHeight: 520, idealHeight: 600)
        .task(id: attempt) { await model.load(rounds: rounds) }
        .onDisappear {
            writeTask?.cancel()
            if model.saved { onChange() }
        }
        .alert(item: $confirmation) { action in
            let withdraw = action == .withdraw
            return Alert(title: Text(withdraw ? "지원을 철회할까요?" : "지원서를 제출할까요?"),
                         message: Text(withdraw ? "이 차수에서 제출한 지원을 철회해요." : "입력한 답변을 제출해요."),
                         primaryButton: withdraw
                         ? .destructive(Text("지원 철회")) { perform(action) }
                         : .default(Text("제출")) { perform(action) },
                         secondaryButton: .cancel(Text("취소")))
        }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.pdf]) { result in
            guard let question = fileQuestion else { return }
            fileQuestion = nil
            switch result {
            case .success(let url): writeTask = Task { await model.upload(file: url, questionId: question) }
            case .failure(let error):
                if (error as NSError).code != NSUserCancelledError { model.failure = error.localizedDescription }
            }
        }
    }

    private func sidebar(_ sections: [MatchingSection], detail: MatchingApplicationDetail) -> some View {
        let required = sections.flatMap(\.questions).filter(\.isRequired)
        let completed = required.filter { model.hasValue($0) }.count
        return VStack(alignment: .leading, spacing: UMCSpacing.value16) {
            MatchingBadge(text: MatchingLabel.status(detail.status))
            Text(model.route.projectName).umcTypography(.title1Bold)
            if let round = model.round { Text(round.name) }
            if let submittedAt = detail.submittedAt {
                Text("제출 · " + MatchingLabel.time(submittedAt)).umcTypography(.bodyRegular)
            }
            if let saved = detail.formResponse?.lastSavedAt {
                Text("마지막 저장 · " + MatchingLabel.time(saved)).umcTypography(.bodyRegular)
            }
            Divider()
            ForEach(sections, id: \.sectionId) { Text($0.title) }
            if !required.isEmpty {
                ProgressView(value: Double(completed), total: Double(required.count))
                Text("필수 질문 \(completed) / \(required.count) 완료").umcTypography(.bodyRegular)
            }
        }
        .matchingPanel().frame(width: 190)
    }

    private func actions(_ sections: [MatchingSection], detail: MatchingApplicationDetail, now: Date) -> some View {
        let isDraft = detail.status == "DRAFT"
        let open = model.round?.isOpen(at: now) == true
        let mutable = isDraft || detail.status == nil || detail.status == "SUBMITTED"
        let complete = sections.flatMap(\.questions).filter(\.isRequired).allSatisfy { model.hasValue($0) }
        return HStack {
            if open, mutable {
                Button("지원 철회", role: .destructive) { confirmation = .withdraw }
            }
            Spacer()
            if model.busy { ProgressView().controlSize(.small) }
            if model.editing {
                if isDraft || (open && mutable) {
                    Button(isDraft ? "임시 저장" : "수정 저장") { perform(.save) }
                        .disabled(!model.archivedQuestions.isEmpty || (!isDraft && !complete))
                }
                if isDraft, open {
                    Button("제출 전 확인") { confirmation = .submit }
                        .buttonStyle(MatchingActionStyle(appearance: .primary))
                        .disabled(!complete || !model.archivedQuestions.isEmpty)
                }
            } else if mutable, open {
                Button("답변 수정") { model.editing = true }
            }
        }
    }

    private func perform(_ action: EditorAction) {
        writeTask = Task { await model.persist(action) { dismiss() } }
    }

    private func field(_ question: MatchingQuestion) -> some View {
        let id = question.questionId
        let label = question.title + (question.isRequired ? ", 필수" : ", 선택")
        let hint = question.description ?? ""
        return VStack(alignment: .leading, spacing: UMCSpacing.value8) {
            Text(question.title + (question.isRequired ? " · 필수" : ""))
                .umcTypography(.headlineBold)
            if let text = question.description { Text(text).foregroundStyle(.secondary) }
            if model.editing, model.archivedQuestions.contains(id) {
                Text("저장한 답변에 현재 폼에서 삭제된 선택지가 있어요.")
                    .foregroundStyle(UMCColor.Semantic.textWarning)
                Text(question.answer?.selectedOptions.compactMap(\.answeredAsContent)
                    .joined(separator: ", ") ?? "")
                Button("삭제된 선택지 답변을 지우고 다시 입력") {
                    let valid = Set(question.options.map(\.optionId))
                    model.answers[id]?.selectedOptionIds.removeAll { !valid.contains($0) }
                    model.archivedQuestions.remove(id)
                }
                .accessibilityLabel(label + ", 삭제된 선택지 답변 지우기")
                .accessibilityHint(hint)
            } else if model.editing {
                switch question.type {
                case "RADIO", "DROPDOWN":
                    Picker(question.title, selection: Binding(
                        get: { model.answers[id]?.selectedOptionIds.first ?? "" },
                        set: { model.answers[id]?.selectedOptionIds = $0.isEmpty ? [] : [$0] }
                    )) {
                        Text("선택").tag("")
                        ForEach(question.options, id: \.optionId) { Text($0.content).tag($0.optionId) }
                    }.labelsHidden()
                    .accessibilityLabel(label)
                    .accessibilityHint(hint)
                case "CHECKBOX":
                    ForEach(question.options, id: \.optionId) { option in
                        Toggle(option.content, isOn: Binding(
                            get: { model.answers[id]?.selectedOptionIds.contains(option.optionId) == true },
                            set: { selected in
                                model.answers[id]?.selectedOptionIds.removeAll { $0 == option.optionId }
                                if selected { model.answers[id]?.selectedOptionIds.append(option.optionId) }
                            }
                        ))
                        .accessibilityLabel(label + ", " + option.content)
                        .accessibilityHint(hint)
                    }
                case "SHORT_TEXT", "LONG_TEXT", "PORTFOLIO":
                    TextField(question.type == "PORTFOLIO" ? "포트폴리오 링크" : "답변 입력",
                              text: Binding(get: { model.answers[id]?.textValue ?? "" },
                                            set: { model.answers[id]?.textValue = $0 }), axis: .vertical)
                    .accessibilityLabel(label)
                    .accessibilityHint(hint)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(question.type == "LONG_TEXT" ? 3...12 : 1...5)
                case "FILE": EmptyView()
                default: Text("이 유형의 답변은 이 앱에서 편집할 수 없어요.")
                }
                if question.type == "FILE" || question.type == "PORTFOLIO" {
                    Button("PDF 파일 선택") { fileQuestion = id; importing = true }
                        .accessibilityLabel(label + ", PDF 파일 선택")
                        .accessibilityHint(hint)
                    ForEach(model.answers[id]?.fileIds ?? [], id: \.self) { fileId in
                        HStack {
                            Text(model.fileNames[fileId] ?? fileId)
                            Button("첨부 해제") { model.answers[id]?.fileIds.removeAll { $0 == fileId } }
                                .accessibilityLabel(label + ", " + (model.fileNames[fileId] ?? fileId) + " 첨부 해제")
                                .accessibilityHint(hint)
                        }
                    }
                }
            } else {
                if let answer = question.answer {
                    if let text = answer.textValue { Text(text).textSelection(.enabled) }
                    ForEach(Array(answer.selectedOptions.enumerated()), id: \.offset) { _, option in
                        Text(option.answeredAsContent ?? question.options.first {
                            $0.optionId == option.questionOptionId
                        }?.content ?? "선택한 항목")
                    }
                    ForEach(answer.files, id: \.fileId) { file in
                        if let url = MatchingLabel.webURL(file.url) {
                            Link(file.originalFileName ?? "첨부 파일", destination: url)
                        } else { Text(file.originalFileName ?? "첨부 파일") }
                    }
                } else { Text("답변 없음").foregroundStyle(.secondary) }
            }
        }
    }
}
