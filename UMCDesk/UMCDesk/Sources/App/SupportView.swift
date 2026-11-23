//
//  SupportView.swift
//  UMCDesk
//
//  Created by euijjang97 on 11/23/26.
//

import CoreDesignSystem
import SwiftUI
import UMCFoundation

struct SupportView: View {
    private enum Page { case answers, inquiries }
    @State private var page = Page.answers
    @State private var search = ""
    @State private var selection: Topic?

    private enum Topic: String, Identifiable, CaseIterable {
        case profile, language, settings
        var id: Self { self }

        var question: String {
            switch self {
            case .profile: AppLocalization.string("프로필 링크는 어디에서 바꾸나요?")
            case .language: AppLocalization.string("앱 언어는 어떻게 바꾸나요?")
            case .settings: AppLocalization.string("설정 창은 어떻게 열고 닫나요?")
            }
        }

        var answer: String {
            switch self {
            case .profile:
                AppLocalization.string("마이페이지의 프로필 링크에서 편집을 선택하세요.")
            case .language:
                AppLocalization.string("설정의 모양에서 앱 언어를 선택하세요.")
            case .settings:
                AppLocalization.string("Command와 쉼표를 함께 누르면 설정이 열려요. Command와 W를 누르면 현재 창이 닫혀요.")
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value20) {
            Text(AppLocalization.string("고객센터")).umcTypography(.largeTitle3Bold)
                .accessibilityAddTraits(.isHeader)
            Picker(AppLocalization.string("고객센터"), selection: $page) {
                Text(AppLocalization.string("많이 묻는 질문")).tag(Page.answers)
                Text(AppLocalization.string("내 문의")).tag(Page.inquiries)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(maxWidth: 300)
            if page == .answers {
                answers
            } else {
                ContentUnavailableView {
                    Label(AppLocalization.string("문의 접수 준비 중"), systemImage: "bubble.left")
                } description: {
                    Text(AppLocalization.string("앱에서 문의를 보내거나 답변을 조회하는 기능을 준비하고 있어요."))
                } actions: {
                    Button(AppLocalization.string("답변 찾아보기")) { page = .answers }
                }
            }
        }
        .padding(UMCSpacing.value32)
        .frame(minWidth: 560, minHeight: 420, alignment: .topLeading)
        .background(UMCColor.Custom.backgroundDefault)
        .onChange(of: page) { selection = nil }
    }

    @ViewBuilder private var answers: some View {
        if let selection {
            Button { self.selection = nil } label: {
                Label(AppLocalization.string("목록으로"), systemImage: "chevron.left")
            }
            ScrollView {
                VStack(alignment: .leading, spacing: UMCSpacing.value16) {
                    Text(selection.question).umcTypography(.title2Bold)
                        .accessibilityAddTraits(.isHeader)
                    Text(selection.answer).umcTypography(.bodyRegular)
                        .textSelection(.enabled)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        } else {
            TextField(AppLocalization.string("궁금한 내용을 검색하세요"), text: $search)
                .textFieldStyle(.roundedBorder)
            let matches = Topic.allCases.filter { topic in
                search.isEmpty || topic.question.localizedCaseInsensitiveContains(search)
                    || topic.answer.localizedCaseInsensitiveContains(search)
            }
            if matches.isEmpty {
                ContentUnavailableView.search(text: search)
            } else {
                List(matches) { topic in
                    Button { selection = topic } label: {
                        HStack {
                            Text(topic.question).umcTypography(.headlineRegular)
                            Spacer()
                            Image(systemName: "chevron.right").accessibilityHidden(true)
                        }
                        .padding(.vertical, UMCSpacing.value8)
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                }
                .listStyle(.inset)
            }
        }
    }
}
