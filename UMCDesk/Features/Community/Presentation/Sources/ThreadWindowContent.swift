//
//  ThreadWindowContent.swift
//  CommunityPresentation
//
//  Created by euijjang97 on 11/23/26.
//

import CommunityDomain
import CoreDesignSystem
import SwiftUI

public struct ThreadWindowKey: Codable, Hashable, Sendable {
    public let accountID: String
    public let threadID: String

    public init(accountID: String, threadID: String) {
        self.accountID = accountID
        self.threadID = threadID
    }
}

extension Notification.Name {
    static let threadBrowserChanged = Notification.Name("CommunityPresentation.threadBrowserChanged")
}

public struct ThreadWindowContent: View {
    private let key: ThreadWindowKey
    private let repository: any CommunityThreadRepository
    private let conversations: any ThreadConversationRepository
    private let management: any ThreadManagementRepository
    private let defaults: UserDefaults

    public init(
        key: ThreadWindowKey, repository: any CommunityThreadRepository,
        conversations: any ThreadConversationRepository, management: any ThreadManagementRepository,
        defaults: UserDefaults = .standard
    ) {
        self.key = key
        self.repository = repository
        self.conversations = conversations
        self.management = management
        self.defaults = defaults
    }

    public var body: some View {
        DetachedThread(key: key, repository: repository, conversations: conversations,
                       management: management, defaults: defaults).id(key)
    }
}

private struct DetachedThread: View {
    let key: ThreadWindowKey
    let repository: any CommunityThreadRepository
    let conversations: any ThreadConversationRepository
    let management: any ThreadManagementRepository
    let defaults: UserDefaults

    @Environment(\.dismissWindow) private var dismissWindow
    @State private var thread: CommunityThread?
    @State private var failure: String?
    @State private var reload = 0

    var body: some View {
        Group {
            if let thread {
                ThreadDestination(accountID: key.accountID, thread: thread, detached: true,
                                  repository: repository, conversations: conversations,
                                  management: management, defaults: defaults)
            } else if let failure {
                ContentUnavailableView {
                    Label("대화를 열 수 없어요", systemImage: "lock")
                } description: { Text(failure) } actions: {
                    Button("다시 시도") { reload += 1 }
                    Button("창 닫기") { dismissWindow(value: key) }
                }
            } else {
                ProgressView("대화를 불러오는 중")
            }
        }
        .frame(minWidth: 380, minHeight: 360)
        .navigationTitle(thread?.title ?? "스레드")
        .task(id: reload) {
            failure = nil
            do {
                let current = try await management.currentMemberID()
                try Task.checkCancellation()
                guard !current.isEmpty, current == key.accountID else {
                    thread = nil
                    failure = "이 대화를 연 계정으로 로그인해 주세요."
                    return
                }
                let fresh = try await repository.thread(id: key.threadID)
                try Task.checkCancellation()
                thread = fresh
            } catch {
                if !Task.isCancelled {
                    thread = nil
                    failure = error.localizedDescription
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .threadBrowserChanged)) { notice in
            guard notice.object as? ThreadWindowKey == key else { return }
            if notice.userInfo?["exit"] as? Bool == true {
                thread = nil
                dismissWindow(value: key)
            } else { reload += 1 }
        }
    }
}

struct ThreadDestination: View {
    let accountID: String
    let thread: CommunityThread
    let detached: Bool
    let repository: any CommunityThreadRepository
    let conversations: any ThreadConversationRepository
    let management: any ThreadManagementRepository
    let defaults: UserDefaults

    @Environment(\.openWindow) private var openWindow
    @State private var destination: ThreadManagementDestination?
    @State private var updated: CommunityThread?
    @State private var mutating = false
    @State private var failure: String?
    @State private var accessFailure: String?
    @State private var refresh = 0

    private var item: CommunityThread { updated ?? thread }
    private var active: Bool { item.isJoined && item.membershipState == "ACTIVE" }
    private var key: ThreadWindowKey { .init(accountID: accountID, threadID: thread.id) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(item.icon).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title).umcTypography(.title3Bold).lineLimit(1)
                    if let count = item.memberCount {
                        Text("참여자 \(count)명").font(.caption).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if !detached {
                    Button("별도 창에서 열기", systemImage: "macwindow.badge.plus") {
                        openWindow(value: key)
                    }.labelStyle(.iconOnly)
                }
                if active && accessFailure == nil {
                    Menu("스레드 설정", systemImage: "ellipsis.circle") {
                        Button("참여자") { destination = .members }
                        if item.myRole == .owner || item.myRole == .admin {
                            Button("참여자 초대") { destination = .invite }
                            Button("스레드 편집") { destination = .edit }
                        }
                        Divider()
                        Button(item.isPinned ? "고정 해제" : "스레드 고정") {
                            change(.pin, !item.isPinned)
                        }
                        Button(item.isMuted ? "알림 켜기" : "알림 끄기") {
                            change(.mute, !item.isMuted)
                        }
                        Divider()
                        Button("스레드 나가기") { destination = .leave }
                        if item.myRole == .owner || item.myRole == .admin {
                            Button("스레드 삭제", role: .destructive) { destination = .delete }
                        }
                    }.labelStyle(.iconOnly).fixedSize().disabled(mutating)
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 20).padding(.vertical, 12)
            Divider()
            if let failure {
                Text(failure).font(.callout).padding(.horizontal, 16)
            }
            if item.membershipState == "KICKED" {
                ContentUnavailableView {
                    Label("이 스레드에서 내보내졌어요", systemImage: "person.crop.circle.badge.minus")
                } actions: {
                    Button("내보내짐 확인") { destination = .acknowledgeKick }
                }
            } else if let accessFailure {
                ContentUnavailableView {
                    Label("대화를 불러올 수 없어요", systemImage: "bubble.left")
                } description: { Text(accessFailure) } actions: {
                    Button("다시 시도") { refresh += 1 }
                }
            } else {
                ThreadConversationView(thread: item, accountID: accountID,
                                       repository: conversations, defaults: defaults)
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity,
               alignment: .topLeading)
        .background(UMCColor.Custom.backgroundDefault)
        .sheet(item: $destination) { target in
            ThreadManagementView(threadID: item.id, destination: target, repository: management,
                                 onChanged: { broadcast(exit: false) },
                                 onExit: { broadcast(exit: true) })
        }
        .onChange(of: thread) { _, fresh in updated = fresh }
        .task(id: refresh) {
            while !Task.isCancelled {
                do {
                    let fresh = try await repository.thread(id: thread.id)
                    try Task.checkCancellation()
                    updated = fresh
                    accessFailure = nil
                    if fresh.membershipState == "KICKED", destination != .acknowledgeKick {
                        destination = nil
                    }
                } catch {
                    if !Task.isCancelled {
                        accessFailure = error.localizedDescription
                        if item.membershipState != "KICKED" { destination = nil }
                    }
                }
                do { try await Task.sleep(for: .seconds(15)) } catch { return }
            }
        }
    }

    private func change(_ preference: ThreadPreference, _ enabled: Bool) {
        guard !mutating else { return }
        mutating = true
        Task { @MainActor in
            defer { mutating = false }
            do {
                updated = try await repository.update(preference, enabled: enabled, id: thread.id)
                failure = nil
                broadcast(exit: false)
            } catch { failure = error.localizedDescription }
        }
    }

    private func broadcast(exit: Bool) {
        if !exit { refresh += 1 }
        NotificationCenter.default.post(name: .threadBrowserChanged, object: key,
                                        userInfo: ["exit": exit])
    }
}
