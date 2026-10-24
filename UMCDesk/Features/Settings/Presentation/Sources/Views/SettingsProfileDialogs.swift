//
//  SettingsProfileDialogs.swift
//  SettingsPresentation
//
//  Created by euijjang97 on 10/20/26.
//

import UMCFoundation
import CoreDesignSystem
import SettingsDomain
import SwiftUI

struct SettingsDialogContent: View {
    @Environment(\.settingsAppearancePalette) private var palette
    let dialog: SettingsDialog
    @Bindable var viewModel: SettingsViewModel
    @FocusState private var focusedLink: SettingsLinkKind?
    @FocusState private var focusesCode: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value24) {
            HStack(alignment: .top, spacing: UMCSpacing.value16) {
                VStack(alignment: .leading, spacing: UMCSpacing.value8) {
                    Text(title)
                        .umcTypography(isCompactForm ? .title2Bold : .largeTitle3Bold)
                        .accessibilityAddTraits(.isHeader)
                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .umcTypography(isCompactForm ? .headlineRegular : .title4Regular)
                            .foregroundStyle(palette.textNeutralMedium600)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if !isCompactForm {
                    Button(action: viewModel.dismissDialog) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18))
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(SettingsPlainButtonStyle())
                    .disabled(isBusy)
                    .accessibilityLabel(AppLocalization.string("닫기"))
                }
            }
            switch dialog {
            case .editLinks: linkEditor
            case .addPermission: challengerForm
            case .logout: logoutConfirmation
            case .clearCache: cacheConfirmation
            case .licenses:
                SettingsLicenseList()
                HStack { Spacer(); cancelButton(title: AppLocalization.string("닫기")) }
            }
        }
        .padding(isCompactForm ? UMCSpacing.value24 : UMCSpacing.value32)
        .frame(width: dialog == .addPermission ? 440 : dialog == .editLinks ? 560 : 640)
        .foregroundStyle(palette.textNeutralDefault)
        .background(palette.backgroundDefault)
        .onExitCommand(perform: viewModel.dismissDialog)
        .onAppear {
            if dialog == .editLinks { focusedLink = viewModel.linkEditorFocus }
            if dialog == .addPermission { focusesCode = true }
        }
    }

    private var linkEditor: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value24) {
            ScrollView { linkFields }
                .scrollBounceBehavior(.basedOnSize)
                .frame(idealHeight: 320, maxHeight: 420)
            HStack(spacing: UMCSpacing.value8) {
                Spacer()
                cancelButton()
                SettingsActionButton(
                    title: viewModel.isSaving
                        ? AppLocalization.string("저장 중") : AppLocalization.string("저장"),
                    kind: .primary
                ) {
                    Task {
                        await viewModel.saveLinks()
                        if let firstError = SettingsLinkKind.allCases.first(where: {
                            viewModel.linkErrors[$0] != nil
                        }) {
                            focusedLink = firstError
                        }
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(viewModel.isAccountBusy)
                .environment(\.colorScheme, .light)
            }
        }
    }

    private var linkFields: some View {
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
                        .umcTypography(.headlineRegular)
                        .padding(.horizontal, UMCSpacing.value12)
                        .padding(.vertical, UMCSpacing.value8)
                        .frame(minHeight: 40)
                        .background(palette.backgroundSurfaceWhite,
                            in: .rect(cornerRadius: UMCRadius.value8))
                        .overlay {
                            RoundedRectangle(cornerRadius: UMCRadius.value8)
                                .strokeBorder(viewModel.linkErrors[kind] != nil ?
                                    UMCColor.Semantic.borderErrorStrong500 :
                                    focusedLink == kind ?
                                        palette.borderPrimaryStrong500 :
                                        palette.borderNeutralMedium300)
                        }
                        .focused($focusedLink, equals: kind)
                        .accessibilityLabel(kind.title)
                        .accessibilityHint(
                            viewModel.linkErrors[kind] ?? AppLocalization.string("프로필 링크 주소")
                        )
                        .disabled(viewModel.isSaving)
                        if let error = viewModel.linkErrors[kind] {
                            Text(error)
                                .umcTypography(.headlineRegular)
                                .foregroundStyle(UMCColor.Semantic.textError)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            Text(AppLocalization.string("저장하면 같은 UMC 계정의 프로필에 반영돼요."))
                .umcTypography(.headlineRegular)
                .foregroundStyle(palette.textNeutralMedium600)
                .fixedSize(horizontal: false, vertical: true)
            dialogError
        }
    }

    @ViewBuilder
    private var challengerForm: some View {
        if viewModel.codeStep == .complete {
            VStack(alignment: .leading, spacing: UMCSpacing.value24) {
                Label(AppLocalization.string("등록이 완료됐어요. 활동 정보를 확인해 주세요."),
                    systemImage: "checkmark.circle.fill")
                    .umcTypography(.title4Regular)
                    .foregroundStyle(palette.textBrandDefault)
                ScrollView {
                    VStack(spacing: UMCSpacing.value8) {
                        ForEach(viewModel.registeredActivities) { activity in
                            SettingsActivityRow(activity: activity)
                        }
                    }
                }
                .scrollBounceBehavior(.basedOnSize)
                .frame(idealHeight: 80, maxHeight: 240)
                HStack(spacing: UMCSpacing.value8) {
                    Spacer()
                    SettingsActionButton(title: AppLocalization.string("다른 코드 등록"), kind: .quiet,
                        action: viewModel.addPermission)
                    SettingsActionButton(
                        title: AppLocalization.string("마이페이지로 돌아가기"), kind: .primary,
                        action: viewModel.dismissDialog)
                        .keyboardShortcut(.defaultAction)
                        .environment(\.colorScheme, .light)
                }
            }
        } else if viewModel.codeStep == .registeredNeedsRefresh {
            VStack(alignment: .leading, spacing: UMCSpacing.value24) {
                SettingsInlineMessage(message: viewModel.dialogMessage ??
                    AppLocalization.string("등록한 활동 정보를 불러오는 중이에요."),
                    isError: viewModel.dialogMessage != nil, typography: .headlineRegular)
                HStack(spacing: UMCSpacing.value8) {
                    Spacer()
                    cancelButton(title: AppLocalization.string("닫기"))
                    SettingsActionButton(
                        title: viewModel.isRegistering
                            ? AppLocalization.string("불러오는 중")
                            :
                        AppLocalization.string("활동 정보 다시 불러오기"), kind: .primary) {
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
                    Text(AppLocalization.string("활동 코드")).umcTypography(.headlineBold)
                    TextField(AppLocalization.string("6자리 코드"), text: $viewModel.challengerCode)
                        .textFieldStyle(.plain)
                        .umcTypography(.headlineRegular)
                        .padding(.horizontal, UMCSpacing.value12)
                        .padding(.vertical, UMCSpacing.value8)
                        .frame(minHeight: 40)
                        .background(palette.backgroundSurfaceWhite,
                            in: .rect(cornerRadius: UMCRadius.value8))
                        .overlay {
                            RoundedRectangle(cornerRadius: UMCRadius.value8)
                                .strokeBorder(viewModel.dialogMessage != nil ?
                                    UMCColor.Semantic.borderErrorStrong500 :
                                    focusesCode ? palette.borderPrimaryStrong500 :
                                        palette.borderNeutralMedium300)
                        }
                        .focused($focusesCode)
                        .accessibilityLabel(AppLocalization.string("활동 코드"))
                        .accessibilityHint(
                            viewModel.dialogMessage ?? AppLocalization.string("6자리 활동 코드")
                        )
                        .disabled(viewModel.isRegistering)
                }
                if viewModel.dialogMessage != nil {
                    dialogError
                    Button(AppLocalization.string("담당 운영진에게 문의")) {
                        viewModel.dismissDialog()
                        viewModel.navigate(to: .about)
                    }
                    .buttonStyle(SettingsPlainButtonStyle())
                    .foregroundStyle(palette.textBrandDefault)
                    .umcTypography(.headlineRegular)
                }
                HStack(spacing: UMCSpacing.value8) {
                    Spacer()
                    cancelButton()
                    SettingsActionButton(
                        title: viewModel.isRegistering
                            ? AppLocalization.string("등록 중") : AppLocalization.string("등록"),
                        kind: .primary) { Task { await viewModel.submitChallengerCode() } }
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
                SettingsActionButton(
                    title: viewModel.isLoggingOut
                        ? AppLocalization.string("로그아웃 중") : AppLocalization.string("로그아웃"),
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
                SettingsActionButton(
                    title: viewModel.isClearingCache
                        ? AppLocalization.string("삭제 중") : AppLocalization.string("캐시 삭제"),
                    kind: .destructive) { Task { await viewModel.clearCache() } }
                    .keyboardShortcut(.defaultAction)
                    .disabled(viewModel.isClearingCache)
            }
        }
    }

    @ViewBuilder
    private var dialogError: some View {
        if let message = viewModel.dialogMessage {
            SettingsInlineMessage(message: message, isError: true,
                typography: isCompactForm ? .headlineRegular : .title4Regular)
        }
    }

    private func cancelButton(title: String = AppLocalization.string("취소")) -> some View {
        SettingsActionButton(title: title, kind: .quiet, action: viewModel.dismissDialog)
            .frame(width: isCompactForm ? nil : 110)
            .keyboardShortcut(.cancelAction)
            .disabled(isBusy)
    }

    private var isCompactForm: Bool { dialog == .editLinks || dialog == .addPermission }

    private var isBusy: Bool { viewModel.isAccountBusy || viewModel.isClearingCache }

    private var title: String {
        switch dialog {
        case .editLinks: AppLocalization.string("프로필 링크 편집")
        case .addPermission:
            switch viewModel.codeStep {
            case .entry: AppLocalization.string("활동 코드 등록")
            case .registeredNeedsRefresh: AppLocalization.string("코드는 등록됐어요")
            case .complete: AppLocalization.string("활동 코드를 등록했어요")
            }
        case .logout: AppLocalization.string("로그아웃할까요?")
        case .clearCache: AppLocalization.string("임시 캐시를 삭제할까요?")
        case .licenses: AppLocalization.string("오픈소스 라이선스")
        }
    }

    private var subtitle: String {
        switch dialog {
        case .editLinks:
            AppLocalization.string("비워 둔 링크는 저장할 때 삭제돼요.")
        case .addPermission:
            viewModel.codeStep == .entry ?
                AppLocalization.string("운영진에게 받은 6자리 코드로 활동과 역할을 추가해요.") : ""
        case .logout:
            AppLocalization.string("이 Mac의 계정 정보와 앱 알림을 정리해요.\n앱 환경 설정은 유지돼요.")
        case .clearCache:
            AppLocalization.string(
                "앱 전용 임시 캐시 \(viewModel.cacheSizeText)를 삭제할게요.\n계정 정보와 환경 설정, 사용자 파일은 보관돼요.")
        case .licenses:
            AppLocalization.string("현재 앱의 의존성과 폰트의 원본 라이선스를 확인할 수 있어요.")
        }
    }
}
