//  NoticeVoteDeadline.swift
//  NoticePresentation
//
//  Created by euijjang97 on 11/27/26.

import Foundation

// Foundation의 ISO 8601 파서는 범위를 벗어난 날짜와 시각을 보정하므로 달력 값도 검증한다.
private let deadlineParser: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXXXX"
    formatter.isLenient = false
    return formatter
}()

/// 공지 투표의 마감 시각을 화면의 언어와 시간대에 맞춰 표시한다.
func noticeVoteDeadline(_ raw: String?, locale: Locale, timeZone: TimeZone) -> String? {
    guard let raw, raw.wholeMatch(of: Date.ISO8601FormatStyle.iso8601) != nil else {
        return nil
    }
    // 분 단위 표시에서 소수 초를 생략하되 원래의 시간대 오프셋을 유지한다.
    let wholeSeconds = raw.replacing(/\.[0-9]+/, with: "")
    guard let date = deadlineParser.date(from: wholeSeconds) else {
        return nil
    }
    return date.formatted(Date.FormatStyle(
        date: .abbreviated, time: .shortened, locale: locale, timeZone: timeZone
    ))
}
