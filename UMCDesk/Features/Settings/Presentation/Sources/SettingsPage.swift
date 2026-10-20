//
//  SettingsPage.swift
//  SettingsPresentation
//
//  Created by euijjang97 on 10/20/26.
//

import Foundation

public enum SettingsPage: String, CaseIterable, Identifiable, Sendable {
    case myPage, general, appearance, notifications, privacy, about

    public var id: String { rawValue }

    var title: String {
        switch self {
        case .myPage: "마이페이지"
        case .general: "일반"
        case .appearance: "모양"
        case .notifications: "알림"
        case .privacy: "개인정보 및 저장 공간"
        case .about: "앱 정보"
        }
    }

    var symbol: String {
        switch self {
        case .myPage: "person.crop.circle"
        case .general: "gearshape"
        case .appearance: "paintpalette"
        case .notifications: "bell"
        case .privacy: "shield.lefthalf.filled"
        case .about: "info.circle"
        }
    }

    static let categories: [Self] = [.general, .appearance, .notifications, .privacy, .about]

    static func search(_ text: String) -> [Self] {
        let query = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return categories }
        return categories.filter {
            ($0.title + " " + $0.searchTerms).localizedCaseInsensitiveContains(query)
        }
    }

    private var searchTerms: String {
        switch self {
        case .myPage: "프로필 링크 활동 권한 계정"
        case .general: "시작 창 앱 로그인 실행 메뉴 막대 백그라운드 링크 브라우저"
        case .appearance: "테마 시스템 라이트 다크 본문 크기 접근성 동작 투명도"
        case .notifications: "macOS 알림 접근 출석 가능 시간 새 공지 스레드 메시지 내용 표시"
        case .privacy: "시스템 권한 위치 접근 저장 공간 임시 캐시 삭제 개인 프로젝트 기록"
        case .about: "UMC Desk 버전 빌드 업데이트 GitHub 이용약관 개인정보 처리방침 라이선스 문의 카카오톡"
        }
    }
}
