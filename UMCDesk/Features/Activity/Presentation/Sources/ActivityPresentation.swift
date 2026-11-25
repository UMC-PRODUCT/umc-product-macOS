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
            }, reload: .management)
    }

    func loadMembers(_ id: String) async {
        members = .loading
        let result = await capture { try await repository.members(groupID: id) }
        if !Task.isCancelled { members = result }
    }

    func perform(_ operation: () async throws -> String, reload tab: ActivityTab) async -> Bool {
        guard !submitting else { return false }
        submitting = true
        defer { submitting = false }
        do {
            feedback = try await operation()
            await load(tab)
            return true
        } catch {
            feedback = error.localizedDescription
            return false
        }
    }

    private func capture<T>(_ operation: () async throws -> T) async -> Loadable<T> {
        do { return .loaded(try await operation()) } catch { return .failed(error) }
    }
}

public struct ActivityView: View {
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
            HStack {
                Picker("활동", selection: Bindable(model).tab) {
                    ForEach(ActivityTab.allCases.filter { $0 != .management || model.canReview }) {
                        Text($0.rawValue).tag($0)
                    }
                }.pickerStyle(.segmented).labelsHidden()
                Button("새로고침", systemImage: "arrow.clockwise") { retry = UUID() }
                    .labelStyle(.iconOnly).disabled(model.submitting)
                if model.capabilities?.canCreate == true {
                    Button("일정 만들기", systemImage: "plus") { presented = .create }
                }
            }.padding(16)
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if let feedback = model.feedback {
                        HStack {
                            Text(feedback).textSelection(.enabled)
                            Spacer()
                            Button("닫기", systemImage: "xmark") { model.feedback = nil }
                                .labelStyle(.iconOnly)
                        }.activityPanel()
                    }
                    switch model.tab {
                    case .attendance:
                        loaded(model.schedules) { schedules in
                            TimelineView(.periodic(from: .now, by: 30)) { timeline in
                                attendance(schedules, now: timeline.date)
                            }
                        }
                    case .study:
                        Text("내 커리큘럼").umcTypography(.largeTitle3Bold)
                        loaded(model.weeks) { rows in rowList(rows, empty: "등록된 주차가 없어요") }
                        Text("스터디 그룹").umcTypography(.largeTitle3Bold)
                        loaded(model.groups) { groups in
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
                                TextField("구성원 이름 검색", text: $memberSearch)
                                loaded(model.members) { rows in
                                    let filtered = rows.filter {
                                        memberSearch.isEmpty
                                            || $0.title.localizedCaseInsensitiveContains(
                                                memberSearch)
                                    }
                                    if filtered.isEmpty { empty("표시할 구성원이 없어요") }
                                    ForEach(filtered) { member in
                                        HStack {
                                            Text(member.title).umcTypography(.headlineBold)
                                            Text(member.detail).foregroundStyle(.secondary)
                                            Spacer()
                                            Button("프로필") { memberProfile = member }
                                        }.activityPanel()
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
                            Text("출석 관리").umcTypography(.largeTitle3Bold)
                            loaded(model.reviews) { reviewRows($0) }
                        }
                    }
                }.frame(maxWidth: .infinity, alignment: .leading).padding(28)
            }
        }
        .background(UMCColor.Custom.backgroundSurface)
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

    @ViewBuilder
    private func loaded<T, Content: View>(
        _ state: Loadable<T>,
        @ViewBuilder content: (T) -> Content
    ) -> some View {
        switch state {
        case .idle, .loading: ProgressView().frame(maxWidth: .infinity).padding()
        case .loaded(let value): content(value)
        case .failed(let error):
            ContentUnavailableView {
                Label("불러오지 못했어요", systemImage: "exclamationmark.circle")
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
            HStack(alignment: .top, spacing: 16) {
                scheduleList("다가오는 일정", schedules.filter { $0.endsAt >= now })
                scheduleList("최근 출석 상태", schedules.filter { $0.status != nil }.reversed())
            }
        }
    }

    private func hero(_ schedule: ActivitySchedule, now: Date) -> some View {
        let open =
            schedule.opens.map { $0 <= now } == true
            && schedule.closes.map { now <= $0 } == true && schedule.endsAt >= now
        let phase =
            open
            ? ((schedule.onTime ?? now) >= now ? "지금 출석 가능" : "지각 출석 가능")
            : ((schedule.closes ?? schedule.endsAt) < now ? "출석 마감" : "출석 시작 전")
        let deadline = (schedule.onTime ?? now) > now ? schedule.onTime : schedule.closes
        let minutes = max(0, Int(ceil((deadline?.timeIntervalSince(now) ?? 0) / 60)))
        return HStack(spacing: 24) {
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
            VStack(alignment: .leading, spacing: 12) {
                Text(status(schedule.status, fallback: phase))
                    .foregroundStyle(UMCColor.Semantic.textBrandDefault)
                Text(schedule.name).umcTypography(.largeTitle3Bold)
                Text(
                    schedule.startsAt.formatted(date: .abbreviated, time: .shortened)
                        + " · " + (schedule.isOnline ? "비대면 일정" : schedule.location ?? "대면 일정"))
                HStack(spacing: 12) {
                    Label("일정 확인", systemImage: "checkmark.circle.fill")
                    Image(systemName: "chevron.right")
                    Text(schedule.isOnline ? "비대면 일정" : "위치 확인")
                    Image(systemName: "chevron.right")
                    Text(schedule.status == nil ? "출석 요청" : "결과 확인")
                }.umcTypography(.calloutRegular).foregroundStyle(.secondary)
                if let onTime = schedule.onTime, let close = schedule.closes {
                    Text(
                        "정시 마감 \(onTime.formatted(date: .omitted, time: .shortened)) · 지각 마감 \(close.formatted(date: .omitted, time: .shortened))"
                    )
                    .umcTypography(.calloutRegular)
                }
                HStack {
                    if schedule.isParticipant, open, schedule.status == nil {
                        Button(schedule.isOnline ? "지금 출석 요청" : "위치 확인 후 출석") {
                            if schedule.isOnline {
                                submitAttendance(schedule)
                            } else {
                                presented = .location(schedule)
                            }
                        }.buttonStyle(.borderedProminent)
                    }
                    if schedule.isParticipant, [nil, "LATE", "ABSENT"].contains(schedule.status) {
                        Button("사유 제출") { presented = .excuse(schedule.id) }
                    }
                    if schedule.status != nil { Button("결과 다시 확인") { retry = UUID() } }
                }.disabled(model.submitting)
            }
            Spacer()
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
                }, reload: .attendance)
        }
    }

    private func scheduleList(_ title: String, _ schedules: [ActivitySchedule]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).umcTypography(.headlineBold)
            if schedules.isEmpty { Text("일정이 없어요").foregroundStyle(.secondary) }
            ForEach(schedules) { schedule in
                Button {
                    selectedSchedule = schedule.id
                } label: {
                    HStack {
                        Text(schedule.startsAt, format: .dateTime.month().day()).umcTypography(
                            .calloutRegular)
                        Text(schedule.name)
                        Spacer()
                        Text(status(schedule.status, fallback: "예정")).umcTypography(
                            .calloutRegular)
                    }.padding(10).background(
                        UMCColor.Custom.backgroundSurface, in: .rect(cornerRadius: 8))
                }.buttonStyle(.plain)
            }
        }.frame(maxWidth: .infinity, alignment: .leading).activityPanel()
    }

    @ViewBuilder
    private func rowList(_ rows: [ActivityRow], empty title: String) -> some View {
        if rows.isEmpty { empty(title) }
        ForEach(rows) { row in
            VStack(alignment: .leading, spacing: 6) {
                Text(row.title).umcTypography(.headlineBold)
                if !row.detail.isEmpty { Text(row.detail).foregroundStyle(.secondary) }
            }.frame(maxWidth: .infinity, alignment: .leading).activityPanel()
        }
    }

    @ViewBuilder
    private func reviewRows(_ rows: [AttendanceReview]) -> some View {
        if rows.isEmpty { empty("검토할 일정이 없어요") }
        ForEach(rows) { schedule in
            VStack(alignment: .leading, spacing: 12) {
                Text(schedule.name).umcTypography(.headlineBold)
                ForEach(schedule.participants) { member in
                    HStack {
                        Text(member.name)
                        if let reason = member.reason { Text(reason).foregroundStyle(.secondary) }
                        Spacer()
                        Text(status(member.status, fallback: "미출석"))
                        if schedule.mayDecide && member.status?.hasSuffix("_PENDING") == true {
                            ForEach([true, false], id: \.self) { approve in
                                Button(approve ? "승인" : "거절") {
                                    model.decision = ReviewDecision(
                                        schedule: schedule.id, member: member.id,
                                        name: member.name, approve: approve)
                                }.disabled(model.submitting)
                            }
                        }
                    }
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
    var id: String {
        switch self {
        case .create: "create"
        case .location(let schedule): "location-" + schedule.id
        case .excuse(let id): "excuse-" + id
        }
    }
}

private extension View {
    func activityPanel() -> some View {
        padding(18).background(
            UMCColor.Custom.backgroundSurfaceGreyWeaker,
            in: .rect(cornerRadius: 14))
    }
}

private struct ActivityForm: View {
    let panel: Panel
    let model: ActivityViewModel
    let dismiss: () -> Void
    @State private var text = ""
    @State private var locationTask: Task<Void, Never>?
    private var trimmed: String { text.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            switch panel {
            case .location(let schedule):
                Text("출석 위치 확인").umcTypography(.title2Bold)
                if let coordinate = schedule.coordinate {
                    let center = CLLocationCoordinate2D(
                        latitude: coordinate.latitude,
                        longitude: coordinate.longitude)
                    Map(
                        initialPosition: .region(
                            MKCoordinateRegion(
                                center: center, latitudinalMeters: 400, longitudinalMeters: 400
                            ))
                    ) {
                        Marker(schedule.location ?? schedule.name, coordinate: center)
                        MapCircle(center: center, radius: AttendanceLocation.radius)
                            .foregroundStyle(UMCColor.Semantic.textBrandDefault.opacity(0.15))
                    }.frame(height: 180).clipShape(.rect(cornerRadius: 12))
                    Text("현재 위치가 일정 장소에서 50m 이내이면 좌표를 전송해 출석을 요청해요.")
                }
                Text("위치를 확인하기 어려우면 모바일 앱을 이용하거나 사유를 제출해 주세요.")
                    .foregroundStyle(.secondary)
            case .excuse:
                Text("출석 사유 제출").umcTypography(.title2Bold)
                TextField("사유를 입력해 주세요", text: $text, axis: .vertical).lineLimit(3...7)
                Text("\(text.count) / 300").umcTypography(.calloutRegular)
            case .create: EmptyView()
            }
            if let message = model.feedback { Text(message).foregroundStyle(.secondary) }
            HStack {
                Spacer()
                Button("닫기", action: dismiss).keyboardShortcut(.cancelAction)
                if case .location(let schedule) = panel {
                    Button("위치 확인 및 출석 요청") { locationTask = Task { await submit() } }
                        .disabled(schedule.coordinate == nil)
                } else {
                    Button("제출") { Task { await submit() } }
                        .buttonStyle(.borderedProminent)
                        .disabled(trimmed.isEmpty || model.submitting || trimmed.count > 300)
                }
            }.disabled(model.submitting)
        }.padding(24).frame(width: 420).interactiveDismissDisabled(model.submitting)
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
                    let coordinate = try await AttendanceLocation.verify(venue)
                    try Task.checkCancellation()
                    _ = try await model.repository.attend(
                        scheduleID: schedule.id, reason: nil,
                        coordinate: coordinate)
                    return "출석을 요청했어요."
                }
            }, reload: .attendance)
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
