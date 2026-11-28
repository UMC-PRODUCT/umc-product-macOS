//  ActivityDisplayTests.swift
//  ActivityPresentationTests
//
//  Created by euijjang97 on 11/27/26.
//

import ActivityDomain
import Foundation
import Testing

@testable import ActivityPresentation

struct ActivityDisplayTests {
    private let start = Date(timeIntervalSince1970: 1_800_000_000)
    private func schedule(
        onTime: Date?, closes: Date?, participant: Bool = true, status: String? = "PRESENT_PENDING"
    ) -> ActivitySchedule {
        ActivitySchedule(
            id: "1", name: "경계", startsAt: start,
            endsAt: start.addingTimeInterval(3600), isOnline: true,
            isParticipant: participant, status: status,
            opens: start.addingTimeInterval(-600), onTime: onTime,
            closes: closes, location: nil)
    }

    @Test func phaseAndDeadlineHaveDifferentEqualityBoundaries() {
        let onTime = start.addingTimeInterval(600)
        let close = start.addingTimeInterval(1800)
        let row = schedule(onTime: onTime, closes: close)
        let before = ActivityTiming(schedule: row, now: onTime.addingTimeInterval(-1))
        #expect(before.phase == "지금 출석 가능")
        #expect(before.deadline == onTime)
        #expect(before.minutes == 1)
        let exact = ActivityTiming(schedule: row, now: onTime)
        #expect(exact.phase == "지금 출석 가능")
        #expect(exact.deadline == close)
        #expect(exact.minutes == 20)
        #expect(exact.remainingSummary?.hasPrefix("지각 마감") == true)
        #expect(
            ActivityTiming(schedule: row, now: onTime.addingTimeInterval(1)).phase == "지각 출석 가능")
        #expect(ActivityTiming(schedule: row, now: close).open)
        #expect(!ActivityTiming(schedule: row, now: close.addingTimeInterval(1)).open)
        #expect(
            ActivityTiming(schedule: row, now: close.addingTimeInterval(1)).remainingSummary == nil
        )
    }

    @Test func attendanceActionRequiresOpenWindowAndUnmarkedParticipant() {
        let closes = start.addingTimeInterval(60)
        let eligible = schedule(onTime: start, closes: closes, status: nil)
        let observer = schedule(onTime: start, closes: closes, participant: false, status: nil)
        #expect(ActivityTiming(schedule: eligible, now: closes).canAttend)
        #expect(!ActivityTiming(schedule: eligible, now: closes.addingTimeInterval(1)).canAttend)
        #expect(!ActivityTiming(schedule: observer, now: start).canAttend)
        #expect(!ActivityTiming(schedule: schedule(onTime: start, closes: closes), now: start).canAttend)
    }

    @Test func studyWritesRequirePermissionForTheCurrentGroup() {
        let allowed = StudyTools(create: true, edit: true, mentor: true)
        let denied = StudyTools(create: false, edit: false, mentor: false)
        #expect(StudyToolsView.Tool.create.permitted(by: allowed, groupID: nil))
        for tool in [StudyToolsView.Tool.rename, .assign, .schedule] {
            #expect(!tool.permitted(by: allowed, groupID: nil))
            #expect(!tool.permitted(by: denied, groupID: "changed"))
            #expect(tool.permitted(by: allowed, groupID: "selected"))
        }
    }

    @Test func missingOnTimePreservesFallbackWithoutInventingDeadline() {
        let close = start.addingTimeInterval(1800)
        let timing = ActivityTiming(schedule: schedule(onTime: nil, closes: close), now: start)
        #expect(timing.phase == "지금 출석 가능")
        #expect(timing.deadline == close)
        let missing = ActivityTiming(schedule: schedule(onTime: nil, closes: nil), now: start)
        #expect(!missing.open)
        #expect(missing.deadline == nil)
        #expect(missing.minutes == 0)
        #expect(missing.remainingSummary == nil)
    }

    @Test func columnsUseContentWidthAndExpandedText() {
        #expect(!ActivityColumns.isHorizontal(width: 815, expandedText: false))
        #expect(ActivityColumns.isHorizontal(width: 816, expandedText: false))
        #expect(ActivityColumns.isHorizontal(width: 817, expandedText: false))
        #expect(!ActivityColumns.isHorizontal(width: 1400, expandedText: true))
    }

    @Test func multiDayIntervalContainsBothDates() {
        let row = ActivitySchedule(
            id: "2", name: "다일", startsAt: start,
            endsAt: start.addingTimeInterval(86400 * 2), isOnline: false,
            isParticipant: false, status: nil, opens: nil, onTime: nil, closes: nil, location: nil)
        #expect(
            ActivityTiming.interval(row).contains(
                row.endsAt.formatted(date: .abbreviated, time: .shortened)))
    }
}
