//
//  DataPreviewWindow.swift
//  UMCDesk
//
//  Created by euijjang97 on 11/25/26.
//

import ActivityPresentation
import AuthData
import AuthPresentation
import CoreNetwork
import CommunityPresentation
import CoreDesignSystem
import CoreRouting
import CoreUIComponents
import HomePresentation
import MatchingDomain
import MatchingPresentation
import NoticePresentation
import ProjectWorkspacePresentation
import SettingsDomain
import SettingsPresentation
import SwiftUI
import UMCFoundation

enum DataPreviewDestination: Hashable {
    case feature(DeskSection)
    case matching, progress, profile, settings, support

    static let all: [Self] = DeskSection.allCases.map(Self.feature) +
        [.matching, .progress, .profile, .settings, .support]

    var title: String {
        switch self {
        case .feature(let section): section.title
        case .matching: "프로젝트 매칭"
        case .progress: "매칭 진행 결과"
        case .profile: "마이페이지"
        case .settings: "설정"
        case .support: "고객센터"
        }
    }
}

@MainActor
@Observable
final class DataPreviewSession {
    let isEmpty: Bool
    private let fixtures: DataPreviewFixtures
    let matching: any MatchingUseCase
    let progress: MatchingProgressController
    let documents: LiveEmailLoginRepository
    let conversations: DataPreviewConversation
    let support: SupportFixture
    let supportExitGate = SupportExitGate()
    var projectID: String?
    private(set) var matchingPage = MatchingDestination.explore
    private(set) var matchingNavigationID = UUID()
    var showsUpdateInfo = false
    private(set) var destination = DataPreviewDestination.feature(.home)
    let defaults: UserDefaults
    let notifications = NotificationCenter()
    let account: FeatureAccount
    let settings: SettingsViewModel

    private let suite = "com.umc.product.macos.data-preview." + UUID().uuidString
    let journalDirectory = URL.temporaryDirectory.appending(path: UUID().uuidString)

    init(isEmpty: Bool = false) {
        self.isEmpty = isEmpty
        fixtures = DataPreviewFixtures(isEmpty: isEmpty)
        matching = MatchingDesignPreview.makeUseCase(isEmpty: isEmpty)
        support = SupportFixture(isEmpty: isEmpty)
        let defaults = UserDefaults(suiteName: suite)!
        self.defaults = defaults
        account = DataPreviewAccount.make(defaults: defaults, journalDirectory: journalDirectory,
                                          baseURL: fixtures.baseURL)
        documents = LiveEmailLoginRepository(client: account.client,
            adapter: MoyaNetworkAdapter(networkClient: account.client), environment: account.environment)
        conversations = DataPreviewConversation(repository: account.conversations)
        progress = MatchingProgressController(repository: matching)
        if !isEmpty { DataPreviewAccount.seedWorkspace(in: defaults) }
        let preferences = SettingsPreferences(defaults: defaults, updatesAppLanguage: false)
        settings = SettingsDesignPreview.workspace(preferences: preferences, isEmpty: isEmpty)
        progress.setAccount(account.memberID)
        progress.openApplications = { [weak self] in
            self?.openMatching(.applications)
        }
    }

    deinit {
        UserDefaults().removePersistentDomain(forName: suite)
        try? FileManager.default.removeItem(at: journalDirectory)
    }

    func openMatching(_ page: MatchingDestination) {
        leavingSupport { [weak self] in self?.applyMatching(page) }
    }

    private func applyMatching(_ page: MatchingDestination) {
        matchingPage = page
        matchingNavigationID = UUID()
        destination = .matching
    }

    func leavingSupport(_ action: @escaping () -> Void) {
        if destination == .support { supportExitGate.request(action) } else { action() }
    }

    func select(_ destination: DataPreviewDestination) {
        if self.destination == .support && destination == .support { return }
        leavingSupport { [weak self] in self?.apply(destination) }
    }

    private func apply(_ destination: DataPreviewDestination) {
        switch destination {
        case .matching: applyMatching(.explore); return
        case .profile: SettingsDesignPreview.prepareViewModel(settings, page: .myPage)
        case .settings: SettingsDesignPreview.prepareViewModel(settings, page: .general)
        default: break
        }
        self.destination = destination
    }
}

@MainActor
@Observable
final class DataPreviewMode {
    private(set) var session: DataPreviewSession?

    func select(_ destination: DataPreviewDestination, isEmpty: Bool? = nil) {
        if let session, isEmpty == nil || (isEmpty == false && !session.isEmpty) {
            session.select(destination)
            return
        }
        startSession(at: destination, isEmpty: isEmpty ?? false)
    }

    func selectAll(isEmpty: Bool) {
        startSession(at: session?.destination ?? .feature(.home), isEmpty: isEmpty)
    }

    private func startSession(at destination: DataPreviewDestination, isEmpty: Bool) {
        let start = { [weak self] in
            guard let self else { return }
            let workspace = DataPreviewSession(isEmpty: isEmpty)
            workspace.settings.onLogout = { [weak self, weak workspace] in
                if self?.session === workspace { self?.end() }
            }
            workspace.select(destination)
            self.session = workspace
        }
        if let session { session.leavingSupport(start) } else { start() }
    }

    func end() {
        session?.leavingSupport { [weak self] in self?.session = nil }
    }
}

struct DataPreviewCommands: Commands {
    @Environment(\.openWindow) private var openWindow
    let mode: DataPreviewMode

    var body: some Commands {
        CommandGroup(after: .toolbar) {
            Menu("데이터 미리보기") {
                previewButton("전체 데이터 있음") { mode.selectAll(isEmpty: false) }
                previewButton("전체 빈 화면") { mode.selectAll(isEmpty: true) }
                Divider()
                ForEach(DataPreviewDestination.all, id: \.self) { destination in
                    if destination == .settings {
                        previewButton(destination.title) { mode.select(destination) }
                    } else {
                        Menu(destination.title) {
                            previewButton("데이터 있음") { mode.select(destination, isEmpty: false) }
                            previewButton("빈 상태") { mode.select(destination, isEmpty: true) }
                        }
                    }
                }
                if mode.session != nil {
                    Divider()
                    Button("미리보기 종료", action: mode.end)
                }
            }
        }
    }

    private func previewButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(title) {
            action()
            openWindow(id: "main")
            NSApplication.shared.activate()
        }
    }
}

struct DataPreviewWindow: View {
    let session: DataPreviewSession
    @State private var externalLink: URL?

    var body: some View {
        @Bindable var session = session
        let preferences = session.settings.preferences
        SettingsView(
            viewModel: session.settings, section: section, featureContent: content,
            matchingSelected: session.destination == .matching, supportSelected: session.destination == .support,
            onOpenMatching: { session.select(.matching) },
            onSelectSection: { session.select($0.map(DataPreviewDestination.feature) ?? .profile) }
        )
        .defaultAppStorage(session.defaults)
        .environment(\.threadNotificationCenter, session.notifications)
        .environment(\.allowsDetachedThreads, false)
        .environment(\.settingsWindowHandler, { id in
            if id == DeskWindow.support { session.select(.support) }
            if id == DeskWindow.updates { session.showsUpdateInfo = true }
        })
        .environment(\.settingsPublishedDocument, { document, close in
            AnyView(AuthPublishedTermsView(repository: session.documents,
                requested: document == .service ? .service : .privacy, onClose: close))
        })
        .environment(\.noticeLocalImage, { [directory = session.journalDirectory] name in
            guard UUID(uuidString: (name as NSString).deletingPathExtension) != nil,
                  name == (name as NSString).lastPathComponent else { return nil }
            return directory.appending(path: name)
        })
        .environment(\.sampleActivityVenue, .init(latitude: 37.55, longitude: 127.04))
        .environment(\.openURL, OpenURLAction { url in
            externalLink = url
            return .handled
        })
        .environment(\.locale, preferences.language.locale)
        .preferredColorScheme(preferences.theme.colorScheme)
        .environment(\.umcBodyTextScale, preferences.bodyTextSize.scale)
        .toggleStyle(UMCCheckboxStyle())
        .frame(minWidth: 1040, minHeight: 720)
        .sheet(isPresented: $session.showsUpdateInfo) {
            AuthUpdateCheckView(usesInstalledRelease: true) { session.showsUpdateInfo = false }
        }
        .alert("미리보기 외부 링크", isPresented: Binding(
            get: { externalLink != nil }, set: { if !$0 { externalLink = nil } }
        )) { Button("닫기", role: .cancel) {} } message: {
            Text(externalLink?.absoluteString ?? "")
        }
    }

    private var section: DeskSection? {
        if case .feature(let section) = session.destination { return section }
        return nil
    }

    private var content: AnyView? {
        switch session.destination {
        case .feature(let section): AnyView(feature(section).id(section))
        case .matching: AnyView(MatchingView(repository: session.matching, gisuId: "10",
            initialDestination: session.matchingPage, memberId: session.account.memberID,
            applicantParts: ["WEB"], onOpenProject: { id in
                session.projectID = id
                session.select(.feature(.projects))
            }).id(session.matchingNavigationID))
        case .progress: AnyView(MatchingProgressPanel(controller: session.progress, onClose: { session.openMatching(.explore) })
            .task { await session.progress.refreshOnce() })
        case .support:
            AnyView(SupportView(fixture: session.support, scene: session.isEmpty ? .empty : .home,
                                exitGate: session.supportExitGate))
        case .profile, .settings: nil
        }
    }

    @ViewBuilder private func feature(_ section: DeskSection) -> some View {
        let account = session.account
        switch section {
        case .home:
            HomeView(repository: account.home, memberID: account.memberID,
                     defaults: session.defaults) {
                switch $0 {
                case .activity: session.select(.feature(.activity))
                case .notice: session.select(.feature(.notice))
                case .project: session.select(.feature(.projects))
                }
            }
        case .notice:
            NoticeBoardView(repository: account.notices)
        case .activity:
            ActivityView(repository: account.activity)
        case .community:
            CommunityPostBoardView(accountID: account.memberID, repository: account.posts)
        case .threads:
            CommunityThreadsView(accountID: account.memberID, repository: account.threads,
                                 conversations: session.conversations,
                                 management: account.members, defaults: session.defaults)
        case .projects:
            ProjectWorkspaceView(accountID: account.memberID, initialProjectID: session.projectID,
                                 loadProjects: account.projects,
                                 loadGitHub: { url in
                                     session.isEmpty ? [] : DataPreviewAccount.recentWork(repository: url)
                                 },
                                 teamContent: { id in
                                     AnyView(PublishedMatchingTeamSheet(repository: session.matching,
                                         projectId: id, memberId: account.memberID))
                                 },
                                 openMatching: { session.select(.matching) })
        }
    }
}
