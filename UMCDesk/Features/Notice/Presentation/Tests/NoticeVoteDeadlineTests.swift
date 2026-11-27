//  NoticeVoteDeadlineTests.swift
//  NoticePresentationTests
//
//  Created by euijjang97 on 11/27/26.

import Foundation
import Testing

@testable import NoticePresentation

struct NoticeVoteDeadlineTests {
    @Test(arguments: ["2026-12-01T16:30:00Z", "2026-12-01T16:30:00.123456789Z"])
    func displaysLocalDateAndTime(_ raw: String) throws {
        let cases = [("Asia/Seoul", "ko_KR", 2, 1), ("UTC", "en_US", 1, 16)]
        for (zone, language, day, hour) in cases {
            let timeZone = try #require(TimeZone(identifier: zone))
            let locale = Locale(identifier: language)
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = timeZone
            let local = DateComponents(year: 2026, month: 12, day: day, hour: hour, minute: 30)
            let expected = try #require(calendar.date(from: local))
            let style = Date.FormatStyle(
                date: .abbreviated, time: .shortened, locale: locale, timeZone: timeZone
            )
            #expect(noticeVoteDeadline(raw, locale: locale, timeZone: timeZone)
                == expected.formatted(style))
        }
    }

    @Test(arguments: [nil, "", "잘못된 시각", "2026-12-01", "2026-12-01T16:30:00Zextra"] as [String?])
    func omitsUnavailableDeadline(_ raw: String?) {
        #expect(noticeVoteDeadline(raw, locale: .current, timeZone: .current) == nil)
    }
}
