//  NoticeVoteDeadline.swift
//  NoticePresentation
//
//  Created by euijjang97 on 11/27/26.

import Foundation

/// 공지 투표의 마감 시각을 화면의 언어와 시간대에 맞춰 표시한다.
func noticeVoteDeadline(_ raw: String?, locale: Locale, timeZone: TimeZone) -> String? {
    guard let date = raw?.wholeMatch(of: Date.ISO8601FormatStyle.iso8601)?.output else {
        return nil
    }
    return date.formatted(Date.FormatStyle(
        date: .abbreviated, time: .shortened, locale: locale, timeZone: timeZone
    ))
}
