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
    private let fixtures = DataPreviewFixtures()
    let matching = MatchingDesignPreview.makeUseCase()
    let progress: MatchingProgressController
    let documents: LiveEmailLoginRepository
    let conversations: DataPreviewConversation
    let support = SupportFixture(emptyInquiries: false)
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

    init() {
        let defaults = UserDefaults(suiteName: suite)!
        self.defaults = defaults
        account = DataPreviewAccount.make(defaults: defaults, journalDirectory: journalDirectory,
                                          baseURL: fixtures.baseURL)
        documents = LiveEmailLoginRepository(client: account.client,
            adapter: MoyaNetworkAdapter(networkClient: account.client), environment: account.environment)
        conversations = DataPreviewConversation(repository: account.conversations)
        progress = MatchingProgressController(repository: matching)
        DataPreviewAccount.seedWorkspace(in: defaults)
        let preferences = SettingsPreferences(defaults: defaults, updatesAppLanguage: false)
        settings = SettingsDesignPreview.workspace(preferences: preferences)
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
        matchingPage = page
        matchingNavigationID = UUID()
        destination = .matching
    }

    func select(_ destination: DataPreviewDestination) {
        switch destination {
        case .matching: openMatching(.explore); return
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

    func select(_ destination: DataPreviewDestination) {
        let workspace = session ?? DataPreviewSession()
        workspace.settings.onLogout = { [weak self] in self?.end() }
        workspace.select(destination)
        session = workspace
    }

    func end() { session = nil }
}

struct DataPreviewCommands: Commands {
    @Environment(\.openWindow) private var openWindow
    let active: Bool
    let end: () -> Void
    let select: (DataPreviewDestination) -> Void

    var body: some Commands {
        CommandGroup(after: .toolbar) {
            Menu("데이터 미리보기") {
                ForEach(DataPreviewDestination.all, id: \.self) { destination in
                    Button(destination.title) {
                        select(destination)
                        openWindow(id: "main")
                        NSApplication.shared.activate()
                    }
                }
                if active {
                    Divider()
                    Button("미리보기 종료", action: end)
                }
            }
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
        case .progress: AnyView(MatchingProgressPanel(controller: session.progress, onClose: { session.select(.matching) })
            .frame(maxWidth: 520, maxHeight: 254).task { await session.progress.refreshOnce() })
        case .support: AnyView(SupportView(fixture: session.support))
        case .profile, .settings: nil
        }
    }

    @ViewBuilder private func feature(_ section: DeskSection) -> some View {
        let account = session.account
        switch section {
        case .home:
            HomeView(repository: account.home, memberID: account.memberID, defaults: session.defaults) {
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
                                 loadGitHub: { _ in DataPreviewAccount.recentWork },
                                 openMatching: { session.select(.matching) })
        }
    }
}
