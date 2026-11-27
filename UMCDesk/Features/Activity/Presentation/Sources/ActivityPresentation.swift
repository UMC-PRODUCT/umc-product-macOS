//  ActivityPresentation.swift
//  ActivityPresentation
//
//  Created by euijjang97 on 11/23/26.
//

import ActivityDomain
import CoreDesignSystem
import MapKit
import SwiftUI
import UMCFoundation

extension EnvironmentValues {
    @Entry public var sampleActivityVenue: ActivityCoordinate?
}

enum ActivityTab: String, CaseIterable, Identifiable {
    case attendance = "출석 체크"
    case study = "스터디/활동"
    case members = "구성원"
    case management = "출석 관리"
    var id: Self { self }
}

@MainActor @Observable
final class ActivityViewModel {
    let repository: any ActivityRepository
    var schedules: Loadable<[ActivitySchedule]> = .idle
    var weeks: Loadable<[ActivityRow]> = .idle
    var groups: Loadable<[ActivityRow]> = .idle
    var members: Loadable<[ActivityRow]> = .idle
    var reviews: Loadable<[AttendanceReview]> = .idle
    var capabilities: ScheduleCapabilities?
    private(set) var canReview = false
    var tab: ActivityTab = .attendance
    var decision: ReviewDecision?
    private var reviewEpoch = UUID()
    var submitting = false
    var feedback: String?
    var feedbackFailed = false
    var feedbackScheduleID: String?

    init(_ repository: any ActivityRepository) { self.repository = repository }

    func load(_ tab: ActivityTab) async {
        switch tab {
        case .attendance:
            schedules = .loading
            let result = await capture { try await repository.schedules() }
            if !Task.isCancelled { schedules = result }
        case .study:
            weeks = .loading
            let result = await capture { try await repository.study() }
            if !Task.isCancelled { weeks = result }
            groups = .loading
            let groupResult = await capture { try await repository.groups() }
            if !Task.isCancelled { groups = groupResult }
        case .members: break
        case .management:
            guard canReview else { return }
            let epoch = reviewEpoch
            reviews = .loading
            let result = await capture { try await repository.reviews() }
            guard !Task.isCancelled, canReview, epoch == reviewEpoch else { return }
            if case .failed(let error) = result, isAccessDenied(error) {
                revokeReviews()
                return
            }
            reviews = result
            if let decision, !canDecide(decision) { self.decision = nil }
        }
    }

    func permissions() async {
        async let create = try? repository.capabilities()
        let epoch = reviewEpoch
        let review = try? await repository.canReadReviews()
        if !Task.isCancelled, epoch == reviewEpoch {
            if review == true { canReview = true } else { revokeReviews() }
        }
        let creation = await create
        if !Task.isCancelled { capabilities = creation }
    }

    private func revokeReviews() {
        reviewEpoch = UUID()
        canReview = false
        reviews = .idle
        decision = nil
        if tab == .management { tab = .attendance }
    }

    private func isAccessDenied(_ error: any Error) -> Bool {
        switch error {
        case NetworkError.unauthorized, NetworkError.requestFailed(statusCode: 401, data: _),
            NetworkError.requestFailed(statusCode: 403, data: _):
            true
        default: false
        }
    }

    func canDecide(_ item: ReviewDecision) -> Bool {
        guard canReview, tab == .management, case .loaded(let rows) = reviews,
            let row = rows.first(where: { $0.id == item.schedule }), row.mayDecide
        else { return false }
        return row.participants.contains {
            $0.id == item.member && $0.status?.hasSuffix("_PENDING") == true
        }
    }

    func decide(_ item: ReviewDecision) async {
        guard canDecide(item) else { return }
        _ = await perform(
            {
                do {
                    try await repository.decide(
                        scheduleID: item.schedule, memberID: item.member,
                        approve: item.approve)
                } catch {
                    if isAccessDenied(error) { revokeReviews() }
                    throw error
                }
                return "출석 판정을 저장했어요."
            }, reload: .management, scheduleID: item.schedule)
    }

    func loadMembers(_ id: String) async {
        members = .loading
        let result = await capture { try await repository.members(groupID: id) }
        if !Task.isCancelled { members = result }
    }

    func perform(
        _ operation: () async throws -> String, reload tab: ActivityTab,
        scheduleID: String? = nil
    ) async -> Bool {
        guard !submitting else { return false }
        submitting = true
        feedbackScheduleID = scheduleID
        defer { submitting = false }
        do {
            feedback = nil
            feedbackFailed = false
            feedback = try await operation()
            await load(tab)
            return true
        } catch {
            feedbackFailed = true
            feedback = error.localizedDescription
            return false
        }
    }

    private func capture<T>(_ operation: () async throws -> T) async -> Loadable<T> {
        do { return .loaded(try await operation()) } catch { return .failed(error) }
    }
}

public struct ActivityView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.umcBodyTextScale) private var textScale
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var model: ActivityViewModel
    @State private var selectedGroup: String?
    @State private var selectedSchedule: String?
    @State private var memberProfile: ActivityRow?
    @State private var memberSearch = ""
    @State private var presented: Panel?
    @State private var retry = UUID()

    public init(repository: any ActivityRepository) {
        _model = State(initialValue: ActivityViewModel(repository))
    }

    public var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                ActivityAdaptiveRow(minimumLeadingWidth: 100) {
                    Text("활동").umcTypography(.title2Bold)
                    HStack(spacing: 12) {
                        Button("새로고침", systemImage: "arrow.clockwise") { retry = UUID() }
                            .labelStyle(.iconOnly).frame(minWidth: 28, minHeight: 28)
                            .help(AppLocalization.string("활동 새로고침")).disabled(model.submitting)
                        if model.capabilities?.canCreate == true {
                            Button("일정 만들기", systemImage: "plus") { presented = .create }
                        }
                    }
                }
                ViewThatFits(in: .horizontal) {
                    tabPicker.pickerStyle(.segmented).fixedSize(horizontal: true, vertical: false)
                    tabPicker.pickerStyle(.menu)
                }
            }.padding(.horizontal, 24).padding(.vertical, 16)
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if model.feedbackScheduleID == nil, let feedback = model.feedback {
                        ActivityFeedback(message: feedback, failed: model.feedbackFailed)
                    }
                    switch model.tab {
                    case .attendance:
                        loaded(model.schedules, section: AppLocalization.string("일정")) {
                            schedules in
                            TimelineView(.periodic(from: .now, by: 30)) { timeline in
                                attendance(schedules, now: timeline.date)
                            }
                        }
                    case .study:
                        Text("내 커리큘럼").umcTypography(.title4Bold)
                        loaded(model.weeks, section: AppLocalization.string("커리큘럼")) { rows in
                            rowList(rows, empty: "등록된 주차가 없어요")
                        }
                        Text("스터디 그룹").umcTypography(.title4Bold)
                        loaded(model.groups, section: "스터디 그룹") { groups in
                            if groups.isEmpty {
                                StudyToolsView(model: model, group: nil) { retry = UUID() }
                                empty("표시할 스터디가 없어요")
                            } else {
                                let id =
                                    selectedGroup.flatMap { selected in
                                        groups.first { $0.id == selected }?.id
                                    } ?? groups[0].id
                                Picker(
                                    "스터디",
                                    selection: Binding(get: { id }, set: { selectedGroup = $0 })
                                ) {
                                    ForEach(groups) { Text($0.title).tag($0.id) }
                                }
                                StudyToolsView(model: model, group: groups.first { $0.id == id }) {
                                    retry = UUID()
                                }
                                TextField(
                                    AppLocalization.string("이 그룹 구성원 이름 검색"), text: $memberSearch)
                                loaded(model.members, section: AppLocalization.string("그룹 구성원")) {
                                    rows in
                                    let filtered = rows.filter {
                                        memberSearch.isEmpty
                                            || $0.title.localizedCaseInsensitiveContains(
                                                memberSearch)
                                    }
                                    if filtered.isEmpty {
                                        empty(
                                            memberSearch.isEmpty
                                                ? "표시할 구성원이 없어요" : "검색 결과가 없어요")
                                    }
                                    ForEach(filtered) { member in
                                        ActivityMemberRow(member: member) {
                                            memberProfile = member
                                        }
                                        ActivityDivider()
                                    }
                                }.task(id: id) { await model.loadMembers(id) }
                            }
                        }
                    case .members:
                        MemberDirectory(repository: model.repository, retry: retry) {
                            memberProfile = $0
                        }
                    case .management:
                        if model.canReview {
                            Text("출석 관리").umcTypography(.title4Bold)
                            loaded(model.reviews, section: AppLocalization.string("출석 명단")) {
                                reviewRows($0)
                            }
                        }
                    }
                }.frame(maxWidth: .infinity, alignment: .leading).padding(24)
            }
        }
        .background(UMCColor.Custom.backgroundDefault)
        .tint(UMCColor.Semantic.textBrandDefault)
        .task(id: LoadKey(tab: model.tab, retry: retry)) { await model.load(model.tab) }
        .task(id: retry) { await model.permissions() }
        .sheet(item: $memberProfile) { member in
            ActivityMemberDetail(repository: model.repository, member: member)
        }
        .sheet(item: $presented) { panel in
            if case .create = panel, let capabilities = model.capabilities {
                ScheduleEditor(model: model, capabilities: capabilities) { presented = nil }
            } else {
                ActivityForm(panel: panel, model: model) { presented = nil }
            }
        }
        .alert(
            "출석 판정을 확정할까요?",
            isPresented: Binding(
                get: { model.canReview && model.decision != nil },
                set: { if !$0 { model.decision = nil } }
            ), presenting: model.decision
        ) { item in
            Button("취소", role: .cancel) {}
            Button(item.approve ? "승인" : "거절") {
                Task { await model.decide(item) }
            }
        } message: {
            Text($0.name + "님의 출석 요청")
        }
    }

    private var tabPicker: some View {
        Picker("활동", selection: Bindable(model).tab) {
            ForEach(ActivityTab.allCases.filter { $0 != .management || model.canReview }) {
                Text($0.rawValue).tag($0)
            }
        }
    }

    @ViewBuilder
    private func loaded<T, Content: View>(
        _ state: Loadable<T>, section: String,
        @ViewBuilder content: (T) -> Content
    ) -> some View {
        switch state {
        case .idle, .loading:
            ProgressView(AppLocalization.string("\(section)을 불러오는 중")).frame(maxWidth: .infinity)
                .padding()
        case .loaded(let value): content(value)
        case .failed(let error):
            ContentUnavailableView {
                Label(
                    AppLocalization.string("\(section)을 불러오지 못했어요"),
                    systemImage: "exclamationmark.circle")
            } description: {
                Text(error.localizedDescription)
            } actions: {
                Button("다시 시도") { retry = UUID() }
            }
        }
    }

    private func empty(_ title: String) -> some View {
        ContentUnavailableView(title, systemImage: "calendar")
    }

    @ViewBuilder
    private func attendance(_ schedules: [ActivitySchedule], now: Date) -> some View {
        if schedules.isEmpty {
            empty("출석할 일정이 없어요")
        } else {
            let current =
                schedules.first { $0.id == selectedSchedule }
                ?? schedules.first {
                    ($0.opens ?? $0.startsAt) <= now && ($0.closes ?? $0.endsAt) >= now
                }
                ?? schedules.first { $0.endsAt > now } ?? schedules[schedules.count - 1]
            hero(current, now: now)
            ActivityColumns(expandedText: textScale > 1 || dynamicTypeSize > .large) {
                scheduleList(
                    "다가오는 일정", schedules.filter { $0.endsAt >= now }, selected: current.id)
                scheduleList(
                    "최근 출석 상태", schedules.filter { $0.status != nil }.reversed(),
                    selected: current.id)
            }
        }
    }

    private func hero(_ schedule: ActivitySchedule, now: Date) -> some View {
        let timing = ActivityTiming(schedule: schedule, now: now)
        let open = timing.open
        let phase = timing.phase
        let deadline = timing.deadline
        let minutes = timing.minutes
        return ActivityAdaptiveRow(
            minimumLeadingWidth: 100, minimumTrailingWidth: 400,
            spacing: 24, trailingFlexible: true
        ) {
            ZStack {
                Circle().stroke(UMCColor.Semantic.backgroundNeutralMedium, lineWidth: 4)
                if let start = schedule.opens, let deadline, deadline > start {
                    let fraction = min(
                        1,
                        max(0, deadline.timeIntervalSince(now) / deadline.timeIntervalSince(start))
                    )
                    Circle().trim(from: 0, to: fraction)
                        .stroke(UMCColor.Semantic.textBrandDefault, lineWidth: 6)
                        .rotationEffect(.degrees(-90))
                }
                VStack {
                    if open && minutes > 0 {
                        Text(String(minutes)).umcTypography(.largeTitle3Bold).monospacedDigit()
                        Text("분 남음").umcTypography(.calloutRegular)
                    } else {
                        Text(schedule.startsAt, format: .dateTime.month())
                            .umcTypography(.calloutRegular)
                        Text(schedule.startsAt, format: .dateTime.day())
                            .umcTypography(.largeTitle3Bold).monospacedDigit()
                    }
                }
            }.frame(width: 100, height: 100)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(timing.accessibilitySummary)
            VStack(alignment: .leading, spacing: 12) {
                Label(phase, systemImage: open ? "clock" : "calendar")
                    .umcTypography(.calloutRegular)
                    .foregroundStyle(UMCColor.Semantic.textBrandDefault)
                ActivityStatus(
                    value: schedule.status, fallback: AppLocalization.string("아직 출석 결과가 없어요")
                )
                .accessibilityLabel(AppLocalization.string("내 출석 결과"))
                .accessibilityValue(
                    status(schedule.status, fallback: AppLocalization.string("아직 출석 결과가 없어요")))
                Text(schedule.name).umcTypography(.largeTitle3Bold)
                    .fixedSize(horizontal: false, vertical: true)
                Text(ActivityTiming.interval(schedule))
                    .umcTypography(.headlineRegular)
                Label(
                    schedule.isOnline ? "비대면 일정" : schedule.location ?? "대면 일정",
                    systemImage: schedule.isOnline ? "video" : "mappin.and.ellipse"
                )
                .umcTypography(.headlineRegular).fixedSize(horizontal: false, vertical: true)
                if let onTime = schedule.onTime, let close = schedule.closes {
                    Text(
                        "정시 마감 " + ActivityTiming.time(onTime, relativeTo: schedule.startsAt)
                            + " · 지각 마감 "
                            + ActivityTiming.time(close, relativeTo: schedule.startsAt)
                    )
                    .umcTypography(.calloutRegular)
                }
                ActivityFlow {
                    if schedule.isParticipant, open, schedule.status == nil {
                        Button(schedule.isOnline ? "지금 출석 요청" : "위치 확인 후 출석") {
                            if schedule.isOnline {
                                submitAttendance(schedule)
                            } else {
                                presented = .location(schedule)
                            }
                        }.buttonStyle(.borderedProminent)
                            .tint(
                                colorScheme == .dark
                                    ? UMCColor.Semantic.fillPrimaryStrong200
                                    : UMCColor.Semantic.textBrandDefault)
                    }
                    if schedule.isParticipant, [nil, "LATE", "ABSENT"].contains(schedule.status) {
                        Button("사유 제출") { presented = .excuse(schedule.id) }
                    }
                    if schedule.status != nil { Button("결과 다시 확인") { retry = UUID() } }
                }.disabled(model.submitting)
                if model.feedbackScheduleID == schedule.id, let feedback = model.feedback {
                    ActivityFeedback(message: feedback, failed: model.feedbackFailed)
                }
            }
        }
        .padding(UMCSpacing.value24)
        .background(UMCColor.Semantic.surfaceBrandWeak, in: .rect(cornerRadius: UMCRadius.value16))
    }

    private func submitAttendance(_ schedule: ActivitySchedule) {
        Task {
            _ = await model.perform(
                {
                    let result = try await model.repository.attend(
                        scheduleID: schedule.id, reason: nil, coordinate: nil)
                    return status(result, fallback: "출석 요청 완료")
                }, reload: .attendance, scheduleID: schedule.id)
        }
    }

    private func scheduleList(
        _ title: String, _ schedules: [ActivitySchedule], selected: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).umcTypography(.title4Bold)
            if schedules.isEmpty { Text("일정이 없어요").umcTypography(.headlineRegular) }
            ForEach(schedules) { schedule in
                ActivityScheduleRow(schedule: schedule, selected: schedule.id == selected) {
                    selectedSchedule = schedule.id
                }
            }
        }.frame(maxWidth: .infinity, alignment: .leading).activityPanel()
    }

    @ViewBuilder
    private func rowList(_ rows: [ActivityRow], empty title: String) -> some View {
        if rows.isEmpty { empty(title) }
        ForEach(rows) { row in
            VStack(alignment: .leading, spacing: 6) {
                Text(row.title).umcTypography(.headlineBold)
                if !row.detail.isEmpty {
                    Text(row.detail).umcTypography(.headlineRegular).foregroundStyle(.secondary)
                }
            }.frame(maxWidth: .infinity, alignment: .leading).activityPanel()
        }
    }

    @ViewBuilder
    private func reviewRows(_ rows: [AttendanceReview]) -> some View {
        if rows.isEmpty { empty("검토할 일정이 없어요") }
        ForEach(rows) { schedule in
            VStack(alignment: .leading, spacing: 12) {
                Text(schedule.name).umcTypography(.title4Bold)
                ForEach(schedule.participants) { member in
                    ActivityAdaptiveRow(minimumLeadingWidth: 360) {
                        VStack(alignment: .leading, spacing: 8) {
                            ActivityFlow {
                                Text(member.name).umcTypography(.headlineBold)
                                ActivityStatus(value: member.status, fallback: "미출석")
                            }
                            if let reason = member.reason {
                                Text(reason).umcTypography(.headlineRegular)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .textSelection(.enabled)
                            }
                        }
                        if schedule.mayDecide && member.status?.hasSuffix("_PENDING") == true {
                            HStack(spacing: 12) {
                                ForEach([true, false], id: \.self) { approve in
                                    Button(approve ? "승인" : "거절") {
                                        model.decision = ReviewDecision(
                                            schedule: schedule.id, member: member.id,
                                            name: member.name, approve: approve)
                                    }
                                    .accessibilityLabel(
                                        approve
                                            ? AppLocalization.string("\(member.name) 출석 승인")
                                            : AppLocalization.string("\(member.name) 출석 거절")
                                    )
                                    .disabled(model.submitting)
                                }
                            }.fixedSize()
                        }
                    }.padding(12)
                    ActivityDivider()
                }
                if model.feedbackScheduleID == schedule.id, let feedback = model.feedback {
                    ActivityFeedback(message: feedback, failed: model.feedbackFailed)
                }
            }.activityPanel()
        }
    }

    private func status(_ value: String?, fallback: String) -> String {
        switch value {
        case "PRESENT": "출석 완료"
        case "LATE": "지각"
        case "ABSENT": "결석"
        case "EXCUSED": "출석 인정"
        case let pending? where pending.hasSuffix("_PENDING"): "승인 대기"
        default: value ?? fallback
        }
    }
}

struct ReviewDecision {
    let schedule: String
    let member: String
    let name: String
    let approve: Bool
}

private struct LoadKey: Equatable {
    let tab: ActivityTab
    let retry: UUID
}

private enum Panel: Identifiable {
    case create
    case excuse(String)
    case location(ActivitySchedule)
    var scheduleID: String? {
        switch self {
        case .create: nil
        case .location(let schedule): schedule.id
        case .excuse(let id): id
        }
    }
    var id: String {
        switch self {
        case .create: "create"
        case .location(let schedule): "location-" + schedule.id
        case .excuse(let id): "excuse-" + id
        }
    }
}

extension View {
    fileprivate func activityPanel() -> some View {
        padding(16).background(
            UMCColor.Custom.backgroundSurfaceGreyWeaker,
            in: .rect(cornerRadius: 16))
    }
}

private struct ActivityForm: View {
    @Environment(\.sampleActivityVenue) private var sampleVenue
    let panel: Panel
    let model: ActivityViewModel
    let dismiss: () -> Void
    @State private var text = ""
    @State private var locationTask: Task<Void, Never>?
    private var trimmed: String { text.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    switch panel {
                    case .location(let schedule):
                        Text("출석 위치 확인").umcTypography(.title2Bold)
                        if let coordinate = schedule.coordinate {
                            if sampleVenue != nil {
                                Label(
                                    schedule.location ?? schedule.name,
                                    systemImage: "mappin.circle")
                                Text("미리보기 장소의 좌표로 출석을 요청해요.")
                            } else {
                                let center = CLLocationCoordinate2D(
                                    latitude: coordinate.latitude,
                                    longitude: coordinate.longitude)
                                Map(
                                    initialPosition: .region(
                                        MKCoordinateRegion(
                                            center: center, latitudinalMeters: 400,
                                            longitudinalMeters: 400
                                        ))
                                ) {
                                    Marker(schedule.location ?? schedule.name, coordinate: center)
                                    MapCircle(center: center, radius: AttendanceLocation.radius)
                                        .foregroundStyle(
                                            UMCColor.Semantic.textBrandDefault.opacity(0.15))
                                }.frame(height: 180).clipShape(.rect(cornerRadius: 12))
                                Text("현재 위치가 일정 장소에서 50m 이내이면 좌표를 전송해 출석을 요청해요.")
                            }
                        }
                        if schedule.coordinate == nil {
                            Text(AppLocalization.string("일정 장소의 좌표가 없어 위치 출석을 요청할 수 없어요."))
                                .foregroundStyle(UMCColor.Semantic.textError)
                        }
                        Text("위치를 확인하기 어려우면 모바일 앱을 이용하거나 사유를 제출해 주세요.")
                            .foregroundStyle(.secondary)
                    case .excuse:
                        Text("출석 사유 제출").umcTypography(.title2Bold)
                        TextField("사유를 입력해 주세요", text: $text, axis: .vertical).lineLimit(3...7)
                        Text("\(text.count) / 300").umcTypography(.calloutRegular)
                        if trimmed.isEmpty || trimmed.count > 300 {
                            Text(AppLocalization.string("앞뒤 공백을 제외한 사유를 1~300자로 입력해 주세요."))
                                .umcTypography(.calloutRegular)
                        }
                    case .create: EmptyView()
                    }
                    if let message = model.feedback {
                        ActivityFeedback(message: message, failed: model.feedbackFailed)
                    }
                }.frame(maxWidth: .infinity, alignment: .leading).padding(24)
            }
            ActivityDivider()
            ActivityFlow(alignment: .trailing) {
                if model.submitting { ProgressView(AppLocalization.string("요청 처리 중")) }
                Button("닫기", action: dismiss).keyboardShortcut(.cancelAction)
                if case .location(let schedule) = panel {
                    Button("위치 확인 및 출석 요청") { locationTask = Task { await submit() } }
                        .buttonStyle(.borderedProminent)
                        .disabled(schedule.coordinate == nil)
                } else {
                    Button("제출") { Task { await submit() } }
                        .buttonStyle(.borderedProminent)
                        .disabled(trimmed.isEmpty || model.submitting || trimmed.count > 300)
                }
            }.padding(16).disabled(model.submitting)
        }.frame(
            minWidth: 420, idealWidth: 480, maxWidth: 600,
            minHeight: 280, idealHeight: 460, maxHeight: 600
        )
        .interactiveDismissDisabled(model.submitting)
        .onAppear { model.feedback = nil }
        .onDisappear { locationTask?.cancel() }
    }

    private func submit() async {
        let saved = await model.perform(
            {
                switch panel {
                case .create: return ""
                case .excuse(let id):
                    _ = try await model.repository.attend(
                        scheduleID: id, reason: trimmed, coordinate: nil)
                    return "사유를 제출했어요."
                case .location(let schedule):
                    guard let venue = schedule.coordinate else {
                        throw AttendanceLocation.Failure.unavailable
                    }
                    let coordinate: ActivityCoordinate
                    if sampleVenue != nil {
                        coordinate = venue
                    } else {
                        coordinate = try await AttendanceLocation.verify(venue)
                    }
                    try Task.checkCancellation()
                    _ = try await model.repository.attend(
                        scheduleID: schedule.id, reason: nil,
                        coordinate: coordinate)
                    return "출석을 요청했어요."
                }
            }, reload: .attendance, scheduleID: panel.scheduleID)
        if saved { dismiss() }
    }
}

public struct ActivityMenuContent: View {
    private let repository: any ActivityRepository
    private let openActivity: () -> Void
    @State private var schedules: Loadable<[ActivitySchedule]> = .idle

    public init(repository: any ActivityRepository, openActivity: @escaping () -> Void) {
        self.repository = repository
        self.openActivity = openActivity
    }

    public var body: some View {
        Section("활동") {
            switch schedules {
            case .idle, .loading: Text("출석 일정 확인 중…")
            case .failed: Text("출석 일정을 확인할 수 없어요")
            case .loaded(let items):
                let open = items.filter {
                    let now = Date.now
                    return $0.isParticipant && ($0.opens ?? .distantFuture) <= now
                        && now <= ($0.closes ?? .distantPast)
                }
                if open.isEmpty { Text("현재 출석 가능한 일정이 없어요") }
                ForEach(open.prefix(3)) { schedule in
                    Button(schedule.name, action: openActivity)
                }
            }
            Button("활동 열기", action: openActivity)
        }.task {
            do { schedules = .loaded(try await repository.schedules()) } catch {
                if !Task.isCancelled { schedules = .failed(error) }
            }
        }
    }
}
