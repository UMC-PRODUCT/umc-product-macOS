//  StudyToolsView.swift
//  ActivityPresentation
//
//  Created by euijjang97 on 11/23/26.
//

import ActivityDomain
import CoreDesignSystem
import SwiftUI

struct StudyToolsView: View {
    let model: ActivityViewModel
    let group: ActivityRow?
    let refresh: () -> Void
    @State private var tools: StudyTools?
    @State private var sheet: Tool?

    var body: some View {
        HStack {
            if tools?.create == true {
                Button("그룹 만들기", systemImage: "plus") { sheet = .create }
            }
            if tools?.edit == true, group != nil {
                Button("그룹 편집") { sheet = .rename }
                Button("멤버·멘토 배정") { sheet = .assign }
            }
            if tools?.mentor == true, group != nil {
                Button("스터디 일정 등록") { sheet = .schedule }
            }
        }
        .task(id: group?.id) {
            tools = nil
            let permissions = try? await model.repository.studyTools(groupID: group?.id)
            if !Task.isCancelled { tools = permissions }
        }
        .sheet(item: $sheet) { tool in
            StudyEditor(repository: model.repository, tool: tool, group: group) {
                sheet = nil
                refresh()
            }
        }
    }

    enum Tool: String, Identifiable {
        case create = "스터디 그룹 만들기"
        case rename = "그룹 편집"
        case assign = "멤버·멘토 배정"
        case schedule = "스터디 일정 등록"
        var id: Self { self }
    }
}

private struct StudyEditor: View {
    let repository: any ActivityRepository
    let tool: StudyToolsView.Tool
    let group: ActivityRow?
    let saved: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var keyword = ""
    @State private var mentors: [ActivityRow] = []
    @State private var members: [ActivityRow] = []
    @State private var results: [ActivityRow] = []
    @State private var asMentor = false
    @State private var schedules: [ActivitySchedule] = []
    @State private var weeks: [ActivityRow] = []
    @State private var scheduleID: String?
    @State private var weekID: String?
    @State private var error: String?
    @State private var working = false
    @State private var searching = false

    private var trimmed: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var valid: Bool {
        switch tool {
        case .create:
            !trimmed.isEmpty && trimmed.count <= 50 && !mentors.isEmpty && !members.isEmpty
        case .rename: !trimmed.isEmpty && trimmed.count <= 50 && trimmed != group?.title
        case .assign: !members.isEmpty || !mentors.isEmpty
        case .schedule: scheduleID != nil && weekID != nil
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(tool.rawValue).umcTypography(.title2Bold)
            if tool == .create || tool == .rename {
                TextField("스터디 그룹명", text: $name)
            }
            if tool == .create || tool == .assign {
                Picker("배정 역할", selection: $asMentor) {
                    Text("스터디원").tag(false)
                    Text("멘토").tag(true)
                }.pickerStyle(.segmented)
                TextField("이름으로 검색", text: $keyword)
                if searching { ProgressView().controlSize(.small) }
                ScrollView {
                    VStack(alignment: .leading) {
                        ForEach(results) { row in
                            HStack {
                                Text(row.title)
                                Text(row.detail).foregroundStyle(.secondary)
                                Spacer()
                                Button("선택") { select(row) }
                            }
                        }
                        if !searching && !keyword.isEmpty && results.isEmpty {
                            Text("검색 결과가 없어요").foregroundStyle(.secondary)
                        }
                    }
                }.frame(height: 100)
                Text("멘토 · " + mentors.map(\.title).joined(separator: ", "))
                Text("스터디원 · " + members.map(\.title).joined(separator: ", "))
                if !members.isEmpty || !mentors.isEmpty {
                    Button("선택 초기화") {
                        mentors = []
                        members = []
                    }
                }
            }
            if tool == .schedule {
                Picker("출석 일정", selection: $scheduleID) {
                    Text("일정 선택").tag(String?.none)
                    ForEach(schedules) { Text($0.name).tag(Optional($0.id)) }
                }
                Picker("주차", selection: $weekID) {
                    Text("주차 선택").tag(String?.none)
                    ForEach(weeks) { Text($0.title).tag(Optional($0.id)) }
                }
            }
            if let error { Text(error).foregroundStyle(.secondary) }
            HStack {
                Spacer()
                Button("취소") { dismiss() }.keyboardShortcut(.cancelAction)
                Button("저장") { Task { await save() } }.buttonStyle(.borderedProminent).disabled(
                    !valid)
            }
        }
        .padding(24).frame(width: 440).disabled(working).interactiveDismissDisabled(working)
        .task {
            if tool == .rename { name = group?.title ?? "" }
            if tool == .schedule {
                do {
                    async let available = repository.schedules()
                    async let curriculum = repository.study()
                    (schedules, weeks) = try await (available, curriculum)
                } catch { self.error = error.localizedDescription }
            }
        }
        .task(id: keyword) {
            let query = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
            results = []
            searching = !query.isEmpty
            guard !query.isEmpty else { return }
            do {
                try await Task.sleep(for: .milliseconds(250))
                let rows = try await repository.searchMembers(keyword: query)
                try Task.checkCancellation()
                results = rows
            } catch {
                if Task.isCancelled { return }
                self.error = error.localizedDescription
            }
            searching = false
        }
    }

    private func select(_ row: ActivityRow) {
        if tool == .assign {
            mentors = []
            members = []
        }
        mentors.removeAll { $0.id == row.id }
        members.removeAll { $0.id == row.id }
        if asMentor { mentors.append(row) } else { members.append(row) }
    }

    private func save() async {
        guard !working, valid else { return }
        working = true
        defer { working = false }
        do {
            switch tool {
            case .create, .rename:
                try await repository.saveGroup(
                    id: tool == .rename ? group?.id : nil, name: trimmed,
                    mentors: mentors.map(\.id), members: members.map(\.id))
            case .assign:
                guard let group, let person = mentors.first ?? members.first else { return }
                try await repository.assign(
                    groupID: group.id, memberID: person.id,
                    mentor: !mentors.isEmpty)
            case .schedule:
                guard let group, let scheduleID, let weekID else { return }
                try await repository.link(
                    groupID: group.id, scheduleID: scheduleID, weekID: weekID)
            }
            saved()
        } catch { self.error = error.localizedDescription }
    }
}

struct ActivityMemberDetail: View {
    let repository: any ActivityRepository
    let member: ActivityRow
    @State private var profile: ActivityMemberProfile?
    @State private var selected: String?
    @State private var canGrant = false
    @State private var amount = ""
    @State private var reason = ""
    @State private var feedback: String?
    @State private var working = false
    @State private var confirming = false
    @State private var operationID = UUID()
    @State private var awaitingLedger = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("구성원 정보").umcTypography(.title2Bold)
            Text(profile?.name ?? member.title).umcTypography(.headlineBold)
            Text(profile?.school ?? member.detail).foregroundStyle(.secondary)
            if let profile, !profile.records.isEmpty {
                Picker("활동 이력", selection: $selected) {
                    ForEach(profile.records) { record in
                        Text(record.title + " · " + record.detail).tag(Optional(record.id))
                    }
                }
            }
            if canGrant {
                Divider()
                Text("포인트 관리").umcTypography(.headlineBold)
                TextField("부여할 점수", text: $amount).disabled(awaitingLedger)
                TextField("지급 사유", text: $reason).disabled(awaitingLedger)
                Button(awaitingLedger ? "지급 원장 다시 확인" : "포인트 지급") {
                    if awaitingLedger { submit() } else { confirming = true }
                }
                .disabled(
                    Int(amount) == nil
                        || reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        || reason.count > 200)
            }
            if let feedback { Text(feedback).foregroundStyle(.secondary) }
            HStack {
                Spacer()
                Button("닫기") { dismiss() }.keyboardShortcut(.cancelAction)
            }
        }
        .frame(width: 360).padding(24).disabled(working).interactiveDismissDisabled(working)
        .task {
            do {
                let loaded = try await repository.memberProfile(id: member.id)
                try Task.checkCancellation()
                profile = loaded
                selected = loaded.records.first?.id
            } catch { if !Task.isCancelled { feedback = error.localizedDescription } }
        }
        .task(id: selected) {
            confirming = false
            awaitingLedger = false
            operationID = UUID()
            amount = ""
            reason = ""
            canGrant = false
            guard let selected else { return }
            let authorized = try? await repository.canGrantPoints(challengerID: selected)
            if !Task.isCancelled { canGrant = authorized == true }
        }
        .alert("포인트를 지급할까요?", isPresented: $confirming) {
            Button("취소", role: .cancel) {}
            Button("지급") { submit() }
        } message: {
            Text("\(member.title)님에게 \(amount)점을 지급합니다.")
        }
    }
    private func submit() {
        guard let selected, canGrant, let value = Int(amount), !working else { return }
        working = true
        Task {
            defer { working = false }
            do {
                let result = try await repository.grantPoints(
                    operationID: operationID, challengerID: selected, value: value, reason: reason)
                awaitingLedger = result == .awaitingLedger
                switch result {
                case .awaitingLedger:
                    feedback = "지급 여부를 확인 중이에요. 원장을 다시 확인해 주세요."
                case .recorded, .ledgerMatch:
                    amount = ""
                    reason = ""
                    operationID = UUID()
                    feedback = result == .recorded ? "포인트를 지급했어요." : "같은 금액과 사유의 새 지급 기록을 확인했어요."
                }
            } catch { feedback = error.localizedDescription }
        }
    }

}

struct MemberDirectory: View {
    let repository: any ActivityRepository
    let retry: UUID
    let open: (ActivityRow) -> Void
    @State private var keyword = ""
    @State private var part: String?
    @State private var page = 0
    @State private var result: ActivityMemberPage?
    @State private var error: String?

    private let parts = [
        "PLAN", "DESIGN", "WEB_PRODUCT_ENGINEER", "MOBILE_PRODUCT_ENGINEER",
        "WEB", "ANDROID", "IOS", "NODEJS", "SPRINGBOOT", "ADMIN",
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("구성원").umcTypography(.largeTitle3Bold)
            HStack {
                TextField("이름 또는 닉네임 검색", text: $keyword)
                Picker("파트", selection: $part) {
                    Text("전체 파트").tag(String?.none)
                    ForEach(parts, id: \.self) { Text($0).tag(Optional($0)) }
                }.labelsHidden().fixedSize()
            }
            if let error {
                Text(error).foregroundStyle(.secondary)
            } else if let result {
                if result.members.isEmpty {
                    ContentUnavailableView("검색 결과가 없어요", systemImage: "person.2")
                }
                ForEach(result.members) { member in
                    HStack {
                        Text(member.title).umcTypography(.headlineBold)
                        Text(member.detail).foregroundStyle(.secondary)
                        Spacer()
                        Button("프로필") { open(member) }
                    }.padding(12).background(
                        UMCColor.Custom.backgroundSurfaceGreyWeaker,
                        in: .rect(cornerRadius: 10))
                }
                if page > 0 || result.hasNext {
                    HStack {
                        Button("이전") { page -= 1 }.disabled(page == 0)
                        Text("\(page + 1)").monospacedDigit()
                        Button("다음") { page += 1 }.disabled(!result.hasNext)
                    }
                }
            } else {
                ProgressView().controlSize(.small)
            }
        }
        .onChange(of: keyword) { page = 0 }
        .onChange(of: part) { page = 0 }
        .task(id: DirectoryQuery(keyword: keyword, part: part, page: page, retry: retry)) {
            result = nil
            error = nil
            do {
                if !keyword.isEmpty { try await Task.sleep(for: .milliseconds(250)) }
                let value = try await repository.directory(
                    keyword: keyword, part: part, page: page)
                try Task.checkCancellation()
                result = value
            } catch { if !Task.isCancelled { self.error = error.localizedDescription } }
        }
    }

    private struct DirectoryQuery: Equatable {
        let keyword: String
        let part: String?
        let page: Int
        let retry: UUID
    }
}
