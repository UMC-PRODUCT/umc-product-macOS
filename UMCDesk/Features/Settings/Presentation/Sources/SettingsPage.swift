//
//  SettingsPage.swift
//  SettingsPresentation
//
//  Created by euijjang97 on 10/20/26.
//

import UMCFoundation
import Foundation

public enum SettingsPage: String, CaseIterable, Identifiable, Sendable {
    case myPage, general, appearance, notifications, privacy, about

    public var id: String { rawValue }

    var title: String {
        switch self {
        case .myPage: AppLocalization.string("마이페이지")
        case .general: AppLocalization.string("일반")
        case .appearance: AppLocalization.string("모양")
        case .notifications: AppLocalization.string("알림")
        case .privacy: AppLocalization.string("개인정보 및 저장 공간")
        case .about: AppLocalization.string("앱 정보")
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

    static func search(_ text: String, language: AppLanguage? = nil) -> [SettingsSearchResult] {
        let query = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return [] }
        return SettingsSearchResult.items(language: language).filter {
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

    static var recommendations: [Self] { [
        "theme", "bodyTextSize", "launchAtLogin", "notificationAccess",
    ].compactMap { identifier in items.first { $0.id == identifier } } }

    // shortcut: 화면 문구와 수동 동기화하며, 설정 항목이 동적으로 바뀌면 공통 정의로 옮긴다.
    static var items: [Self] { items(language: nil) }

    static func items(language: AppLanguage?) -> [Self] { [
            .init(
                id: "launchPage", page: .general,
                title: AppLocalization.string("시작 화면", language: language),
                summary: AppLocalization.string(
                    "앱을 완전히 종료한 뒤 다시 실행할 때 적용돼요. 로그인 · 마이페이지 · 설정", language: language)),
            .init(
                id: "launchAtLogin", page: .general,
                title: AppLocalization.string("Mac 로그인 시 자동 실행", language: language),
                summary: AppLocalization.string(
                    "이 Mac에 로그인하면 UMC Desk를 실행해요. macOS 로그인 항목 설정", language: language)),
            .init(
                id: "menuBar", page: .general,
                title: AppLocalization.string("메뉴 막대에 표시", language: language),
            summary: AppLocalization.string("메뉴 막대에서 앱을 빠르게 열어요.", language: language)),
            .init(
                id: "windowClose", page: .general,
                title: AppLocalization.string("마지막 창을 닫으면", language: language),
                summary: AppLocalization.string(
                    "계속 실행 · 앱 종료. 계속 실행하면 Dock에서 앱을 다시 열 수 있어요.", language: language)),
            .init(
                id: "externalLinks", page: .general,
                title: AppLocalization.string("기본 웹 브라우저", language: language),
                summary: AppLocalization.string(
                    "외부 링크는 Mac의 기본 브라우저로 열어요. 시스템 설정 > 데스크탑 및 Dock에서 변경해요.", language: language)),
            .init(
                id: "theme", page: .appearance,
                title: AppLocalization.string("앱 모드", language: language),
                summary: AppLocalization.string(
                    "시스템 · 라이트 · 다크. 시스템은 macOS의 밝은 화면 · 어두운 화면 설정을 따라요.", language: language)),
            .init(
                id: "colorTheme", page: .appearance,
                title: AppLocalization.string("테마 프리셋", language: language),
                summary: AppLocalization.string(
                    "UMC · Graphite · Midnight · Paper · Ocean · 사용자 테마 복제 · 삭제",
                    language: language)),
            .init(
                id: "themeColors", page: .appearance,
                title: AppLocalization.string("테마 색상", language: language),
                summary: AppLocalization.string(
                    "사이드바와 콘텐츠의 배경색·글자색. 라이트·다크 모드별 색상 편집", language: language)),
        .init(id: "language", page: .appearance,
            title: AppLocalization.string("앱 언어", language: language),
            summary: AppLocalization.string("한국어 · 영어 · 앱 전체의 표시 언어", language: language)),
            .init(
                id: "font", page: .appearance,
                title: AppLocalization.string("글꼴", language: language),
                summary: AppLocalization.string(
                    "Pretendard · 시스템 · 둥근 글꼴 · 세리프 · Mac에 설치된 폰트", language: language)),
            .init(
                id: "bodyTextSize", page: .appearance,
                title: AppLocalization.string("본문 크기", language: language),
            summary: AppLocalization.string("앱 본문과 설명의 크기예요. 기본 · 크게 · 더 크게", language: language)),
            .init(
                id: "resetAppearance", page: .appearance,
                title: AppLocalization.string("모양 기본값으로 복원", language: language),
                summary: AppLocalization.string(
                    "앱 모드·테마·글꼴·본문 크기를 기본값으로 되돌려요. 저장한 사용자 테마는 유지해요.", language: language)),
            .init(
                id: "accessibility", page: .appearance,
                title: AppLocalization.string("동작 줄이기 · 투명도 줄이기", language: language),
            summary: AppLocalization.string("macOS의 접근성 설정을 그대로 따라요.", language: language)),
            .init(
                id: "notificationAccess", page: .notifications,
                title: AppLocalization.string("알림 접근", language: language),
                summary: AppLocalization.string(
                    "이 Mac에서 알림을 표시하려면 접근을 허용해 주세요. macOS 설정 열기", language: language)),
            .init(
                id: "attendanceNotifications", page: .notifications,
                title: AppLocalization.string("출석 가능 시간", language: language),
                summary: AppLocalization.string(
                    "준비 중 · 출석 알림 연결 시 사용할 수신 설정이에요.", language: language)),
            .init(
                id: "noticeNotifications", page: .notifications,
                title: AppLocalization.string("새 공지", language: language),
                summary: AppLocalization.string(
                    "준비 중 · 공지 알림 연결 시 사용할 수신 설정이에요.", language: language)),
            .init(
                id: "threadNotifications", page: .notifications,
                title: AppLocalization.string("스레드 메시지", language: language),
                summary: AppLocalization.string(
                    "준비 중 · 메시지 알림 연결 시 사용할 수신 설정이에요.", language: language)),
            .init(
                id: "notificationContent", page: .notifications,
                title: AppLocalization.string("알림 내용 표시", language: language),
                summary: AppLocalization.string(
                    "준비 중 · 알림 연결 시 이름 · 제목 · 본문 표시 여부예요.", language: language)),
            .init(
                id: "locationAccess", page: .privacy,
                title: AppLocalization.string("위치 접근", language: language),
                summary: AppLocalization.string(
                    "시스템에서 변경할 수 있어요. 현재 위치를 수집하지 않아요.", language: language)),
            .init(
                id: "cache", page: .privacy,
                title: AppLocalization.string("임시 캐시", language: language),
                summary: AppLocalization.string(
                    "앱 전용 임시 캐시 폴더의 파일만 삭제해요. 용량 다시 확인", language: language)),
        .init(id: "appVersion", page: .about, title: "UMC Desk",
            summary: AppLocalization.string("앱 버전 · 빌드", language: language)),
            .init(
                id: "updates", page: .about,
                title: AppLocalization.string("업데이트", language: language),
                summary: AppLocalization.string(
                    "공개 GitHub Releases에서 게시된 버전을 확인해요. 자동으로 설치하지 않아요.", language: language)),
        .init(id: "terms", page: .about, title: AppLocalization.string("이용약관", language: language),
            summary: AppLocalization.string("서비스 이용에 필요한 약관을 확인해요. 준비 중", language: language)),
            .init(
                id: "privacyPolicy", page: .about,
                title: AppLocalization.string("개인정보 처리방침", language: language),
            summary: AppLocalization.string("개인정보 처리와 보관 기준을 확인해요. 준비 중", language: language)),
            .init(
                id: "licenses", page: .about,
                title: AppLocalization.string("오픈소스 라이선스", language: language),
            summary: AppLocalization.string("앱에 사용한 오픈소스 정보를 확인해요.", language: language)),
            .init(
                id: "contact", page: .about,
                title: AppLocalization.string("문의하기(카카오톡)", language: language),
            summary: AppLocalization.string("도움이 필요하거나 의견이 있나요? 준비 중", language: language)),
    ] }
}
