//
//  SettingsProfileDialogs.swift
//  SettingsPresentation
//
//  Created by euijjang97 on 10/20/26.
//

import UMCFoundation
import CoreDesignSystem
import SettingsDomain
import CoreRouting
import AppKit
import SwiftUI

struct SettingsDialogContent: View {
    @Environment(\.settingsAppearancePalette) private var palette
    @Environment(\.settingsOpenWindow) private var openWindow
    let dialog: SettingsDialog
    @Bindable var viewModel: SettingsViewModel
    private enum LinkFocus: Hashable {
        case field(SettingsLinkKind), clear(SettingsLinkKind)
    }

    @FocusState private var linkFocus: LinkFocus?
    @FocusState private var focusesCode: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: dialog == .editLinks ?
                UMCSpacing.value32 : UMCSpacing.value24) {
            HStack(alignment: .top, spacing: UMCSpacing.value16) {
                VStack(alignment: .leading, spacing: UMCSpacing.value8) {
                    Text(title)
                        .umcTypography(dialog == .addPermission ? .title2Bold : .largeTitle3Bold)
                        .accessibilityAddTraits(.isHeader)
                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .umcTypography(dialog == .addPermission ? .headlineRegular : .title4Regular)
                            .foregroundStyle(palette.textNeutralMedium600)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if dialog == .editLinks {
                    LinkEditorCloseButton(
                        receivesInitialFocus: viewModel.linkEditorFocus == nil,
                        focusFirstField: { linkFocus = .field(.github) },
                        action: viewModel.dismissDialog
                    )
                    .frame(width: 32, height: 32)
                    .disabled(isBusy)
                } else if dialog != .addPermission {
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
        .padding(dialog == .addPermission ? UMCSpacing.value24 : UMCSpacing.value32)
        .frame(width: dialog == .addPermission ? 440 : 640)
        .foregroundStyle(palette.textNeutralDefault)
        .background(palette.backgroundDefault)
        .onExitCommand(perform: viewModel.dismissDialog)
        .onAppear {
            if dialog == .editLinks, let kind = viewModel.linkEditorFocus {
                linkFocus = .field(kind)
            }
            if dialog == .addPermission { focusesCode = true }
        }
    }

    private var linkEditor: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value32) {
            ScrollView { linkFields }
                .scrollBounceBehavior(.basedOnSize)
                .frame(idealHeight: 330, maxHeight: 420)
            HStack(spacing: UMCSpacing.value12) {
                Spacer()
                SettingsActionButton(
                    title: AppLocalization.string("취소"), kind: .quiet, fillsWidth: true,
                    action: viewModel.dismissDialog
                )
                .frame(width: 110)
                .keyboardShortcut(.cancelAction)
                .disabled(isBusy)
                SettingsActionButton(
                    title: viewModel.isSaving
                        ? AppLocalization.string("저장 중") : AppLocalization.string("저장"),
                    kind: .primary, fillsWidth: true
                ) {
                    Task {
                        await viewModel.saveLinks()
                        if let firstError = SettingsLinkKind.allCases.first(where: {
                            viewModel.linkErrors[$0] != nil
                        }) {
                            linkFocus = .field(firstError)
                        }
                    }
                }
                .frame(width: 110)
                .keyboardShortcut(.defaultAction)
                .disabled(viewModel.isAccountBusy)
                .environment(\.colorScheme, .light)
            }
        }
    }

    private var linkFields: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value12) {
            ForEach(SettingsLinkKind.allCases) { kind in
                HStack(alignment: .center, spacing: UMCSpacing.value12) {
                    Text(kind.title)
                        .umcTypography(.headlineBold)
                        .frame(width: 80, alignment: .leading)
                    VStack(alignment: .leading, spacing: UMCSpacing.value4) {
                        linkField(kind)
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

    private func linkField(_ kind: SettingsLinkKind) -> some View {
        let active = linkFocus == .field(kind) || linkFocus == .clear(kind)
        let value = Binding(
            get: { viewModel.linkDraft[kind] },
            set: {
                guard $0 != viewModel.linkDraft[kind] else { return }
                viewModel.linkDraft[kind] = $0
                viewModel.linkErrors[kind] = nil
            }
        )
        return HStack(spacing: UMCSpacing.value8) {
            TextField("https://...", text: value)
                .textFieldStyle(.plain)
                .umcTypography(.title3Regular)
                .focused($linkFocus, equals: .field(kind))
                .background {
                    if viewModel.linkEditorFocus == kind {
                        InitialLinkCaret()
                    }
                }
                .accessibilityLabel(kind.title)
                .accessibilityHint(
                    viewModel.linkErrors[kind] ?? AppLocalization.string("프로필 링크 주소"))
            if active && !value.wrappedValue.isEmpty {
                Button {
                    value.wrappedValue = ""
                    linkFocus = .field(kind)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(palette.iconNeutralMedium500)
                        .frame(width: 24, height: 32)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .focused($linkFocus, equals: .clear(kind))
                .accessibilityLabel(AppLocalization.string("\(kind.title) 지우기"))
            }
        }
        .padding(.horizontal, UMCSpacing.value16)
        .frame(minHeight: 50)
        .background {
            RoundedRectangle(cornerRadius: UMCRadius.value12).fill(palette.backgroundSurfaceWhite)
            if active {
                RoundedRectangle(cornerRadius: UMCRadius.value12)
                    .fill(palette.fillPrimaryWeak75.opacity(0.35))
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: UMCRadius.value12).strokeBorder(
                viewModel.linkErrors[kind] != nil ? UMCColor.Semantic.borderErrorStrong500 :
                    active ? palette.borderPrimaryStrong500 : palette.borderNeutralMedium300)
        }
        .disabled(viewModel.isSaving)
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
                    SettingsActivityList(activities: viewModel.registeredActivities)
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
                        openWindow(DeskWindow.support)
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
            Bundle.module.localizedString(forKey: "profileLinks.description", value: nil,
                table: "ProfileLinks",
                localizations: [AppLocalization.shared.language.locale.language])
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

private struct LinkEditorCloseButton: NSViewRepresentable {
    let receivesInitialFocus: Bool
    let focusFirstField: () -> Void
    let action: () -> Void

    func makeNSView(context: Context) -> CloseButton {
        let button = CloseButton()
        button.isBordered = false
        button.imagePosition = .imageOnly
        button.image = NSImage(systemSymbolName: "xmark", accessibilityDescription: nil)?
            .withSymbolConfiguration(.init(pointSize: 18, weight: .regular))
        button.target = button
        button.action = #selector(CloseButton.closeEditor)
        return button
    }

    func updateNSView(_ button: CloseButton, context: Context) {
        button.receivesInitialFocus = receivesInitialFocus
        button.focusFirstField = focusFirstField
        button.onClose = action
        button.isEnabled = context.environment.isEnabled
        button.setAccessibilityLabel(AppLocalization.string("닫기"))
    }

    final class CloseButton: NSButton {
        var receivesInitialFocus = false
        var focusFirstField: (() -> Void)?
        var onClose: (() -> Void)?
        override var acceptsFirstResponder: Bool { true }
        override var canBecomeKeyView: Bool { !isHidden && isEnabled }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            if let window, receivesInitialFocus {
                window.initialFirstResponder = self
                window.makeFirstResponder(self)
            }
        }

        override func keyDown(with event: NSEvent) {
            if event.charactersIgnoringModifiers == "\t",
               event.modifierFlags.intersection([.command, .control, .option, .shift]).isEmpty {
                focusFirstField?()
            } else {
                super.keyDown(with: event)
            }
        }

        @objc func closeEditor() { onClose?() }
    }
}

// AppKit selects the full URL when a field receives initial keyboard focus.
private struct InitialLinkCaret: NSViewRepresentable {
    func makeNSView(context: Context) -> Anchor { Anchor() }
    func updateNSView(_ nsView: Anchor, context: Context) {}

    final class Anchor: NSView {
        private var completed = false

        override func hitTest(_ point: NSPoint) -> NSView? { nil }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            NotificationCenter.default.removeObserver(self)
            guard window != nil else { return }
            NotificationCenter.default.addObserver(
                self, selector: #selector(selectionChanged),
                name: NSTextView.didChangeSelectionNotification, object: nil
            )
            selectionChanged()
        }

        @objc private func selectionChanged() {
            guard !completed else { return }
            DispatchQueue.main.async { [weak self] in
                guard let self, !completed,
                      let editor = window?.firstResponder as? NSTextView,
                      let field = editor.delegate as? NSTextField,
                      field.window === window,
                      field.convert(field.bounds, to: self).intersects(bounds)
                else { return }
                completed = true
                let end = (editor.string as NSString).length
                editor.setSelectedRange(NSRange(location: end, length: 0))
                NotificationCenter.default.removeObserver(self)
            }
        }
    }
}
