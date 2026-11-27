//  ScheduleEditor.swift
//  ActivityPresentation
//
//  Created by euijjang97 on 11/23/26.
//

import ActivityDomain
import CoreDesignSystem
import CoreUIComponents
import MapKit
import SwiftUI

struct ScheduleEditor: View {
    @Environment(\.sampleActivityVenue) private var sampleVenue
    let model: ActivityViewModel
    let capabilities: ScheduleCapabilities
    let dismiss: () -> Void

    @State private var title = ""
    @State private var memo = ""
    @State private var tag = "GENERAL"
    @State private var start = Date.now.addingTimeInterval(3600)
    @State private var end = Date.now.addingTimeInterval(7200)
    @State private var onsite = false
    @State private var venue = ""
    @State private var point: CLLocationCoordinate2D?
    @State private var track = false
    @State private var opens = Date.now.addingTimeInterval(3000)
    @State private var onTime = Date.now.addingTimeInterval(4200)
    @State private var closes = Date.now.addingTimeInterval(5400)
    @State private var keyword = ""
    @State private var results: [ActivityRow] = []
    @State private var selected: [ActivityRow] = []
    @State private var searchError: String?
    @State private var isSearching = false

    private var valid: Bool {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed.count <= 100 && start < end
            && (!onsite
                || (point != nil && !venue.trimmingCharacters(in: .whitespaces).isEmpty
                    && venue.count <= 100))
            && (!track
                || (!selected.isEmpty && opens < start && start < onTime
                    && onTime < closes && closes < end))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("일정 만들기").umcTypography(.title2Bold).padding([.horizontal, .top])
            Form {
                Section("기본 정보") {
                    TextField("일정명", text: $title)
                    DatePicker("시작", selection: $start)
                    DatePicker("종료", selection: $end)
                    Picker("태그", selection: $tag) {
                        Text("일반").tag("GENERAL")
                        Text("스터디").tag("STUDY")
                        Text("프로젝트").tag("PROJECT")
                        Text("발표").tag("PRESENTATION")
                        Text("회의").tag("MEETING")
                    }
                    TextField("메모", text: $memo, axis: .vertical)
                    Picker("진행 방식", selection: $onsite) {
                        Text("비대면").tag(false)
                        Text("대면").tag(true)
                    }.pickerStyle(.segmented)
                    if onsite {
                        TextField("장소명", text: $venue)
                        if let sampleVenue {
                            Button {
                                point = .init(latitude: sampleVenue.latitude, longitude: sampleVenue.longitude)
                                if venue.isEmpty { venue = "학생회관 세미나실" }
                            } label: {
                                Label(point == nil ? "예시 장소 선택" : "예시 장소 선택됨",
                                      systemImage: point == nil ? "mappin" : "checkmark")
                            }
                        } else {
                            Text("지도를 눌러 일정 장소를 선택해 주세요.").umcTypography(.calloutRegular)
                            MapReader { proxy in
                                Map {
                                    if let point { Marker(venue, coordinate: point) }
                                }.onTapGesture { position in
                                    point = proxy.convert(position, from: .local)
                                }
                            }.frame(height: 160)
                        }
                    }
                }
                if capabilities.canTrack {
                    Section("출석 인정 시간") {
                        Toggle("출석 체크", isOn: $track).toggleStyle(UMCCheckboxStyle())
                        if track {
                            DatePicker("출석 시작", selection: $opens)
                            DatePicker("정시 인정 마감", selection: $onTime)
                            DatePicker("지각 인정 마감", selection: $closes)
                            Text("출석 시작 → 일정 시작 → 정시 마감 → 지각 마감 → 일정 종료")
                                .umcTypography(.calloutRegular).foregroundStyle(.secondary)
                        }
                    }
                }
                Section("참여자 · \(selected.count)명 선택") {
                    ForEach(selected) { member in
                        HStack {
                            Text(member.title)
                            Spacer()
                            Button("제외") { selected.removeAll { $0.id == member.id } }
                        }
                    }
                    TextField("이름으로 검색", text: $keyword)
                    if isSearching { ProgressView().controlSize(.small) }
                    if let searchError { Text(searchError).foregroundStyle(.secondary) }
                    if !keyword.isEmpty && results.isEmpty && !isSearching && searchError == nil {
                        Text("검색 결과가 없어요").foregroundStyle(.secondary)
                    }
                    ForEach(results.filter { row in !selected.contains { $0.id == row.id } }) {
                        row in
                        HStack {
                            Text(row.title)
                            Text(row.detail).foregroundStyle(.secondary)
                            Spacer()
                            Button("추가") { selected.append(row) }
                                .disabled(
                                    selected.count >= (Int(capabilities.participantLimit) ?? 0))
                        }
                    }
                }
            }.formStyle(.grouped)
            if let feedback = model.feedback { Text(feedback).padding(.horizontal) }
            HStack {
                Spacer()
                Button("취소", action: dismiss).keyboardShortcut(.cancelAction)
                Button("일정 만들기") { Task { await save() } }
                    .buttonStyle(.borderedProminent).disabled(!valid)
            }.padding([.horizontal, .bottom])
        }
        .frame(minWidth: 510, idealHeight: 560, maxHeight: 720)
        .disabled(model.submitting).interactiveDismissDisabled(model.submitting)
        .onAppear { model.feedback = nil }
        .task(id: keyword) {
            let query = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
            results = []
            searchError = nil
            isSearching = !query.isEmpty
            guard !query.isEmpty else { return }
            do {
                try await Task.sleep(for: .milliseconds(250))
                let members = try await model.repository.searchMembers(keyword: query)
                try Task.checkCancellation()
                results = members
            } catch {
                if Task.isCancelled { return }
                searchError = error.localizedDescription
            }
            isSearching = false
        }
    }

    private func save() async {
        let coordinate =
            onsite
            ? point.map {
                ActivityCoordinate(
                    latitude: $0.latitude,
                    longitude: $0.longitude)
            } : nil
        let draft = ScheduleDraft(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            memo: memo, tag: tag, start: start, end: end,
            venue: onsite ? venue : nil, coordinate: coordinate,
            policy: track
                ? AttendanceWindow(
                    open: opens, onTime: onTime,
                    close: closes) : nil,
            members: selected.map(\.id))
        if await model.perform(
            {
                try await model.repository.createSchedule(draft)
                return "일정을 만들었어요."
            }, reload: .attendance)
        {
            dismiss()
        }
    }
}
