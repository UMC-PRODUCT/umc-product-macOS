//
//  SupportArticle.swift
//  UMCDesk
//
//  Created by euijjang97 on 11/23/26.
//

import Foundation
import UMCFoundation

struct SupportArticle: Identifiable, Equatable {
    let id: String
    var question: String
    var answer: String
    var category: String = ""
    var dayReaders: Int?
    var weekReaders: Int?

    func matches(_ query: String) -> Bool {
        let term = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return term.isEmpty || category.localizedStandardContains(term) || question.localizedStandardContains(term)
            || answer.localizedStandardContains(term)
    }

    static var appGuide: [Self] {
        [
            Self(
                id: "profile",
                question: AppLocalization.string("프로필 링크는 어디에서 바꾸나요?"),
                answer: AppLocalization.string("마이페이지의 프로필 링크에서 편집을 선택하세요."),
                category: AppLocalization.string("마이페이지")
            ),
            Self(
                id: "language",
                question: AppLocalization.string("앱 언어는 어떻게 바꾸나요?"),
                answer: AppLocalization.string("설정의 모양에서 앱 언어를 선택하세요."),
                category: AppLocalization.string("모양")
            ),
            Self(
                id: "settings",
                question: AppLocalization.string("설정 창은 어떻게 열고 닫나요?"),
                answer: AppLocalization.string(
                    "Command와 쉼표를 함께 누르면 설정이 열려요. Command와 W를 누르면 현재 창이 닫혀요."
                ),
                category: AppLocalization.string("일반")
            )
        ]
    }
}
