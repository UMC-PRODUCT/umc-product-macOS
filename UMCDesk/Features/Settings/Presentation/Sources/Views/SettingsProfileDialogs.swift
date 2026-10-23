//
//  SettingsProfileDialogs.swift
//  SettingsPresentation
//
//  Created by euijjang97 on 10/20/26.
//

import CoreDesignSystem
import SettingsDomain
import SwiftUI

struct SettingsDialogContent: View {
    let dialog: SettingsDialog
    @Bindable var viewModel: SettingsViewModel
    @FocusState private var focusedLink: SettingsLinkKind?
    @FocusState private var focusesCode: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value24) {
            HStack(alignment: .top, spacing: UMCSpacing.value16) {
                VStack(alignment: .leading, spacing: UMCSpacing.value8) {
                    Text(title)
                        .umcTypography(.largeTitle3Bold)
                        .accessibilityAddTraits(.isHeader)
                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .umcTypography(.title4Regular)
                            .foregroundStyle(UMCColor.Semantic.textNeutralMedium600)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Button(action: viewModel.dismissDialog) {
                    Image(systemName: "xmark")
                        .font(.system(size: 18))
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(SettingsPlainButtonStyle())
                .disabled(isBusy)
                .accessibilityLabel("닫기")
            }
            switch dialog {
            case .editLinks: linkEditor
            case .addPermission: challengerForm
            case .logout: logoutConfirmation
            case .clearCache: cacheConfirmation
            case .licenses:
                SettingsLicenseList()
                HStack { Spacer(); cancelButton(title: "닫기") }
            }
        }
        .padding(UMCSpacing.value32)
        .frame(width: 640)
        .foregroundStyle(UMCColor.Semantic.textNeutralDefault)
        .background(UMCColor.Custom.backgroundDefault)
        .onAppear {
            if dialog == .editLinks { focusedLink = viewModel.linkEditorFocus }
            if dialog == .addPermission { focusesCode = true }
        }
    }

    private var linkEditor: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value16) {
            ForEach(SettingsLinkKind.allCases) { kind in
                HStack(alignment: .firstTextBaseline, spacing: UMCSpacing.value12) {
                    Text(kind.title)
                        .umcTypography(.headlineBold)
                        .frame(width: 80, alignment: .leading)
                    VStack(alignment: .leading, spacing: UMCSpacing.value4) {
                        TextField("https://...", text: Binding(
                            get: { viewModel.linkDraft[kind] },
                            set: {
                                viewModel.linkDraft[kind] = $0
                                viewModel.linkErrors[kind] = nil
                            }
                        ))
                        .textFieldStyle(.plain)
                        .umcTypography(.title3Regular)
                        .padding(.horizontal, UMCSpacing.value16)
                        .frame(height: 50)
                        .background(UMCColor.Custom.backgroundSurfaceWhite,
                            in: .rect(cornerRadius: UMCRadius.value12))
                        .overlay {
                            RoundedRectangle(cornerRadius: UMCRadius.value12)
                                .strokeBorder(viewModel.linkErrors[kind] != nil ?
                                    UMCColor.Semantic.borderErrorStrong500 :
                                    focusedLink == kind ?
                                        UMCColor.Semantic.borderPrimaryStrong500 :
                                        UMCColor.Semantic.borderNeutralMedium300)
                        }
                        .focused($focusedLink, equals: kind)
                        .accessibilityLabel(kind.title)
                        .disabled(viewModel.isSaving)
                        if let error = viewModel.linkErrors[kind] {
                            Text(error)
                                .umcTypography(.headlineRegular)
                                .foregroundStyle(UMCColor.Semantic.textError)
                        }
                    }
                }
            }
            Text("저장하면 같은 UMC 계정의 프로필에 반영돼요.")
                .umcTypography(.headlineRegular)
                .foregroundStyle(UMCColor.Semantic.textNeutralMedium600)
            dialogError
            HStack(spacing: UMCSpacing.value12) {
                Spacer()
                cancelButton()
                SettingsActionButton(title: viewModel.isSaving ? "저장 중" : "저장", kind: .primary) {
                    Task { await viewModel.saveLinks() }
                }
                .frame(width: 110)
                .keyboardShortcut(.defaultAction)
                .disabled(viewModel.isAccountBusy)
                .environment(\.colorScheme, .light)
            }
            .padding(.top, UMCSpacing.value8)
        }
    }

    @ViewBuilder
    private var challengerForm: some View {
        if viewModel.codeStep == .complete {
            VStack(alignment: .leading, spacing: UMCSpacing.value24) {
                Label("등록이 완료됐어요. 활동 정보를 확인해 주세요.",
                    systemImage: "checkmark.circle.fill")
                    .umcTypography(.title4Regular)
                    .foregroundStyle(UMCColor.Semantic.textBrandDefault)
                ForEach(viewModel.registeredActivities) { activity in
                    SettingsActivityRow(activity: activity)
                }
                HStack(spacing: UMCSpacing.value12) {
                    SettingsActionButton(title: "다른 코드 등록", kind: .quiet,
                        action: viewModel.addPermission)
                    Spacer()
                    SettingsActionButton(title: "마이페이지로 돌아가기", kind: .primary,
                        action: viewModel.dismissDialog)
                        .keyboardShortcut(.defaultAction)
                        .environment(\.colorScheme, .light)
                }
            }
        } else if viewModel.codeStep == .registeredNeedsRefresh {
            VStack(alignment: .leading, spacing: UMCSpacing.value24) {
                SettingsInlineMessage(message: viewModel.dialogMessage ??
                    "등록한 활동 정보를 불러오는 중이에요.",
                    isError: viewModel.dialogMessage != nil)
                HStack(spacing: UMCSpacing.value12) {
                    Spacer()
                    cancelButton(title: "닫기")
                    SettingsActionButton(title: viewModel.isRegistering ? "불러오는 중" :
                        "활동 정보 다시 불러오기", kind: .primary) {
                        Task { await viewModel.retryRegisteredProfile() }
                    }
                    .disabled(viewModel.isRegistering)
                    .keyboardShortcut(.defaultAction)
                    .environment(\.colorScheme, .light)
                }
            }
        } else {
            VStack(alignment: .leading, spacing: UMCSpacing.value16) {
                VStack(alignment: .leading, spacing: UMCSpacing.value4) {
                    Text("챌린저 코드").umcTypography(.title3Regular)
                    TextField("6자리 코드를 입력해 주세요.", text: $viewModel.challengerCode)
                        .textFieldStyle(.plain)
                        .umcTypography(.title3Regular)
                        .padding(.horizontal, UMCSpacing.value16)
                        .frame(height: 50)
                        .background(UMCColor.Custom.backgroundSurfaceWhite,
                            in: .rect(cornerRadius: UMCRadius.value12))
                        .overlay {
                            RoundedRectangle(cornerRadius: UMCRadius.value12)
                                .strokeBorder(viewModel.dialogMessage != nil ?
                                    UMCColor.Semantic.borderErrorStrong500 :
                                    UMCColor.Semantic.borderNeutralMedium300)
                        }
                        .focused($focusesCode)
                        .accessibilityLabel("챌린저 코드")
                        .disabled(viewModel.isRegistering)
                }
                if viewModel.dialogMessage == nil {
                    Text("6자리 코드를 그대로 입력하거나 붙여넣으세요.")
                        .umcTypography(.headlineRegular)
                        .foregroundStyle(UMCColor.Semantic.textNeutralMedium600)
                } else {
                    dialogError
                    Button("담당 운영진에게 문의") {
                        viewModel.dismissDialog()
                        viewModel.navigate(to: .about)
                    }
                    .buttonStyle(SettingsPlainButtonStyle())
                    .foregroundStyle(UMCColor.Semantic.textBrandDefault)
                    .umcTypography(.headlineRegular)
                }
                HStack(spacing: UMCSpacing.value12) {
                    Spacer()
                    cancelButton()
                    SettingsActionButton(title: viewModel.isRegistering ? "등록 중" : "등록",
                        kind: .primary) { Task { await viewModel.submitChallengerCode() } }
                        .frame(width: 110)
                        .disabled(!viewModel.canSubmitCode)
                        .keyboardShortcut(.defaultAction)
                        .environment(\.colorScheme, .light)
                }
                .padding(.top, UMCSpacing.value8)
            }
        }
    }

    private var logoutConfirmation: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value24) {
            dialogError
            HStack(spacing: UMCSpacing.value12) {
                Spacer()
                cancelButton()
                SettingsActionButton(title: viewModel.isLoggingOut ? "로그아웃 중" : "로그아웃",
                    kind: .destructive) { Task { await viewModel.logout() } }
                    .keyboardShortcut(.defaultAction)
                    .disabled(viewModel.isLoggingOut)
            }
        }
    }

    private var cacheConfirmation: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value24) {
            dialogError
            HStack(spacing: UMCSpacing.value12) {
                Spacer()
                cancelButton()
                SettingsActionButton(title: viewModel.isClearingCache ? "삭제 중" : "캐시 삭제",
                    kind: .destructive) { Task { await viewModel.clearCache() } }
                    .keyboardShortcut(.defaultAction)
                    .disabled(viewModel.isClearingCache)
            }
        }
    }

    @ViewBuilder
    private var dialogError: some View {
        if let message = viewModel.dialogMessage {
            SettingsInlineMessage(message: message, isError: true)
        }
    }

    private func cancelButton(title: String = "취소") -> some View {
        SettingsActionButton(title: title, kind: .quiet, action: viewModel.dismissDialog)
            .frame(width: 110)
            .keyboardShortcut(.cancelAction)
            .disabled(isBusy)
    }

    private var isBusy: Bool { viewModel.isAccountBusy || viewModel.isClearingCache }

    private var title: String {
        switch dialog {
        case .editLinks: "프로필 링크 편집"
        case .addPermission:
            switch viewModel.codeStep {
            case .entry: "활동 코드 등록"
            case .registeredNeedsRefresh: "코드는 등록됐어요"
            case .complete: "활동 코드를 등록했어요"
            }
        case .logout: "로그아웃할까요?"
        case .clearCache: "임시 캐시를 삭제할까요?"
        case .licenses: "오픈소스 라이선스"
        }
    }

    private var subtitle: String {
        switch dialog {
        case .editLinks:
            "UMC 프로필에 저장할 링크를 입력하세요. 비워 둔 링크는 프로필에서 삭제돼요."
        case .addPermission:
            viewModel.codeStep == .entry ?
                "운영진에게 받은 6자리 코드를 입력하세요.\n등록하면 이 계정에 활동과 역할이 추가돼요." : ""
        case .logout:
            "이 Mac의 계정 정보와 앱 알림을 정리해요.\n앱 환경 설정은 유지돼요."
        case .clearCache:
            "앱 전용 임시 캐시 \(viewModel.cacheSizeText)를 삭제할게요.\n계정 정보와 환경 설정, 사용자 파일은 보관돼요."
        case .licenses:
            "현재 앱의 의존성과 폰트의 원본 라이선스를 확인할 수 있어요."
        }
    }
}
