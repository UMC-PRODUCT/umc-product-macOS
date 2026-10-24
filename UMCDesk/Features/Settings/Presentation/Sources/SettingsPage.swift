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

    static func search(_ text: String) -> [SettingsSearchResult] {
        let query = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return [] }
        return SettingsSearchResult.items.filter {
            $0.title.localizedCaseInsensitiveContains(query)
                || $0.summary.localizedCaseInsensitiveContains(query)
        }
    }
}

struct SettingsSearchResult: Identifiable {
    let id: String
    let page: SettingsPage
    let title: String
    let summary: String

    static let recommendations: [Self] = [
        "theme", "bodyTextSize", "launchAtLogin", "notificationAccess",
    ].compactMap { identifier in items.first { $0.id == identifier } }

    // shortcut: 화면 문구와 수동 동기화하며, 설정 항목이 동적으로 바뀌면 공통 정의로 옮긴다.
    static let items: [Self] = [
        .init(id: "launchPage", page: .general, title: "시작 화면",
            summary: "앱을 완전히 종료한 뒤 다시 실행할 때 적용돼요. 로그인 · 마이페이지 · 설정"),
        .init(id: "launchAtLogin", page: .general, title: "Mac 로그인 시 자동 실행",
            summary: "이 Mac에 로그인하면 UMC Desk를 실행해요. macOS 로그인 항목 설정"),
        .init(id: "menuBar", page: .general, title: "메뉴 막대에 표시",
            summary: "메뉴 막대에서 앱을 빠르게 열어요."),
        .init(id: "windowClose", page: .general, title: "마지막 창을 닫으면",
            summary: "계속 실행 · 앱 종료. 계속 실행하면 Dock에서 앱을 다시 열 수 있어요."),
        .init(id: "externalLinks", page: .general, title: "기본 웹 브라우저",
            summary: "외부 링크는 Mac의 기본 브라우저로 열어요. 시스템 설정 > 데스크탑 및 Dock에서 변경해요."),
        .init(id: "theme", page: .appearance, title: "테마",
            summary: "시스템 · 라이트 · 다크. 시스템은 macOS의 밝은 화면 · 어두운 화면 설정을 따라요."),
        .init(id: "bodyTextSize", page: .appearance, title: "본문 크기",
            summary: "앱 본문과 설명의 크기예요. 기본 · 크게 · 더 크게 · 미리보기"),
        .init(id: "resetAppearance", page: .appearance, title: "모양 기본값으로 복원",
            summary: "테마는 시스템, 본문 크기는 기본으로 되돌려요."),
        .init(id: "accessibility", page: .appearance, title: "동작 줄이기 · 투명도 줄이기",
            summary: "macOS의 접근성 설정을 그대로 따라요."),
        .init(id: "notificationAccess", page: .notifications, title: "알림 접근",
            summary: "이 Mac에서 알림을 표시하려면 접근을 허용해 주세요. macOS 설정 열기"),
        .init(id: "attendanceNotifications", page: .notifications, title: "출석 가능 시간",
            summary: "준비 중 · 출석 알림 연결 시 사용할 수신 설정이에요."),
        .init(id: "noticeNotifications", page: .notifications, title: "새 공지",
            summary: "준비 중 · 공지 알림 연결 시 사용할 수신 설정이에요."),
        .init(id: "threadNotifications", page: .notifications, title: "스레드 메시지",
            summary: "준비 중 · 메시지 알림 연결 시 사용할 수신 설정이에요."),
        .init(id: "notificationContent", page: .notifications, title: "알림 내용 표시",
            summary: "준비 중 · 알림 연결 시 이름 · 제목 · 본문 표시 여부예요."),
        .init(id: "locationAccess", page: .privacy, title: "위치 접근",
            summary: "시스템에서 변경할 수 있어요. 현재 위치를 수집하지 않아요."),
        .init(id: "cache", page: .privacy, title: "임시 캐시",
            summary: "앱 전용 임시 캐시 폴더의 파일만 삭제해요. 용량 다시 확인"),
        .init(id: "appVersion", page: .about, title: "UMC Desk",
            summary: "앱 버전 · 빌드"),
        .init(id: "updates", page: .about, title: "업데이트",
            summary: "공개 GitHub Releases에서 게시된 버전을 확인해요. 자동으로 설치하지 않아요."),
        .init(id: "terms", page: .about, title: "이용약관",
            summary: "서비스 이용에 필요한 약관을 확인해요. 준비 중"),
        .init(id: "privacyPolicy", page: .about, title: "개인정보 처리방침",
            summary: "개인정보 처리와 보관 기준을 확인해요. 준비 중"),
        .init(id: "licenses", page: .about, title: "오픈소스 라이선스",
            summary: "앱에 사용한 오픈소스 정보를 확인해요."),
        .init(id: "contact", page: .about, title: "문의하기(카카오톡)",
            summary: "도움이 필요하거나 의견이 있나요? 준비 중"),
    ]
}
