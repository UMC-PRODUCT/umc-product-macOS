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
    private func schedule(onTime: Date?, closes: Date?) -> ActivitySchedule {
        ActivitySchedule(
            id: "1", name: "경계", startsAt: start,
            endsAt: start.addingTimeInterval(3600), isOnline: true,
            isParticipant: true, status: "PRESENT_PENDING",
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
        #expect(exact.accessibilitySummary.hasPrefix("지각 마감"))
        #expect(
            ActivityTiming(schedule: row, now: onTime.addingTimeInterval(1)).phase == "지각 출석 가능")
        #expect(ActivityTiming(schedule: row, now: close).open)
        #expect(!ActivityTiming(schedule: row, now: close.addingTimeInterval(1)).open)
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
