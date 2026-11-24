//
//  ThreadConversationModel.swift
//  CommunityPresentation
//
//  Created by euijjang97 on 11/23/26.
//

import CommunityDomain
import Foundation
import Observation
import UniformTypeIdentifiers

@MainActor @Observable
final class ThreadConversationModel {
    let accountID: String
    let threadID: String
    private let repository: any ThreadConversationRepository
    private let store: WindowStore
    private var accessRevoked = false
    private var revision = 0
    private var pages = 1
    private var readID: String?
    private var retryOperation: (@MainActor () async throws -> Void)?
    private var operation: Task<Void, Never>?
    private var draft: Draft {
        get { store.draft }
        set { store.draft = newValue }
    }
    struct Outgoing: Identifiable {
        fileprivate var snapshot: Draft
        var id: String { snapshot.key }
        var content: String { snapshot.text }
        var files: [Attachment] { snapshot.files }
        let createdAt = Date()
        var failure: String?
        var retryable = true
    }

    var outgoing: [Outgoing] { store.outgoing }
    var draftIsOutgoing: Bool { outgoing.contains { $0.id == draft.key } }

    var composerText: String {
        get { draftIsOutgoing ? "" : text }
        set {
            guard !accessRevoked else { return }
            if draftIsOutgoing { draft = Draft() }
            text = newValue
        }
    }
    var messages: [ThreadConversationMessage] = []
    var cursor: String?
    var loaded = false
    var busy = false
    var failure: String?
    let summary = ThreadSummarySession()
    var cooldown = false
    var canRetry = true
    var text: String {
        get { draft.text }
        set {
            if !accessRevoked, draft.text != newValue {
                retryOperation = nil
                draft.key = UUID().uuidString.lowercased()
                draft.text = newValue
            }
        }
    }
    var reply: String? { draft.reply }
    var attachments: [Attachment] { draft.files }
    var canSend: Bool {
        loaded && !busy && !cooldown && !store.sending && text.unicodeScalars.count <= 2_000
            && !outgoing.contains { $0.id == draft.key && !$0.retryable }
            && (!text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                || !attachments.isEmpty)
    }

    init(threadID: String, accountID: String, repository: any ThreadConversationRepository,
         defaults: UserDefaults) {
        self.threadID = threadID
        self.accountID = accountID
        self.repository = repository
        store = WindowStore.shared(defaults: defaults, accountID: accountID, threadID: threadID)
        store.windows.add(self)
        if let end = store.accessEnd { revokeAccess(end) }
    }

    func observe(active: Bool) async {
        let listener = Task { [self] in
            guard active else { return }
            while !Task.isCancelled && !accessRevoked {
                do {
                    try await repository.observeChanges(thread: threadID) { [weak self] in
                        await self?.refresh()
                    }
                } catch { /* REST backfill remains available while reconnecting. */  }
                do { try await Task.sleep(for: .seconds(5)) } catch { return }
            }
        }
        defer { listener.cancel() }
        while !Task.isCancelled && !accessRevoked {
            await refresh()
            if active, !Task.isCancelled, loaded, let last = messages.last?.id, last != readID {
                do {
                    try await repository.perform(.read(message: last), thread: threadID)
                    if !accessRevoked { readID = last }
                } catch {
                    if !Task.isCancelled { _ = revokeAccessIfNeeded(error) }
                }
            }
            do { try await Task.sleep(for: .seconds(6)) } catch { return }
        }
    }

    func refresh(older: Bool = false) async {
        // LEFT members may still read history. Only a newly opened membership can restore writes.
        guard !accessRevoked else { return }
        revision += 1
        let current = revision
        let count = older ? pages + 1 : pages
        do {
            var before: String?
            var ids = Set<String>()
            var rows: [ThreadConversationMessage] = []
            var visited = Set<String>()
            for _ in 0..<count {
                let page = try await repository.history(thread: threadID, before: before)
                try Task.checkCancellation()
                guard current == revision else { return }
                rows += page.values.filter { ids.insert($0.id).inserted }
                before = page.cursor
                guard let before, visited.insert(before).inserted else { break }
            }
            let timeline = Array(rows.reversed())
            if messages != timeline { summary.close() }
            messages = timeline
            cursor = before
            pages = count
            if !loaded {
                canRetry = true
                failure = nil
            }
            loaded = true
            if let reply = draft.reply, messages.contains(where: { $0.id == reply && $0.isHidden })
            {
                selectReply(nil)
            }
        } catch {
            guard !Task.isCancelled, current == revision else { return }
            if revokeAccessIfNeeded(error) { return }
            messages = []
            summary.close()
            cursor = nil
            loaded = false
            failure = error.localizedDescription
        }
    }

    func members(query: String) async throws -> [ThreadManagementPerson] {
        guard !accessRevoked else { throw CancellationError() }
        let members = try await repository.members(thread: threadID, query: query)
        guard !accessRevoked else { throw CancellationError() }
        return members
    }

    func mention(_ person: ThreadManagementPerson) {
        guard !accessRevoked else { return }
        if draftIsOutgoing { draft = Draft() }
        var selected = draft.mentions ?? [:]
        guard selected.count < 100 else { return }
        selected[person.memberId] = person.name
        text +=
            (text.isEmpty || text.last?.isWhitespace == true ? "" : " ") + "@" + person.name + " "
        draft.mentions = selected
    }

    func selectReply(_ id: String?) {
        guard !accessRevoked else { return }
        if draftIsOutgoing { draft = Draft() }
        retryOperation = nil
        draft.key = UUID().uuidString.lowercased()
        draft.reply = id
    }

    func removeFile(_ id: String) {
        guard !accessRevoked else { return }
        retryOperation = nil
        draft.key = UUID().uuidString.lowercased()
        if let file = draft.files.first(where: { $0.id == id }),
           !outgoing.contains(where: { $0.files.contains(where: { $0.id == id }) }) {
            file.discardLocalCopy()
        }
        draft.files.removeAll { $0.id == id }
    }

    func attach(_ urls: [URL]) {
        guard !accessRevoked else { return }
        guard !urls.isEmpty, (draftIsOutgoing ? 0 : attachments.count) + urls.count <= 4 else {
            failure = "사진은 한 번에 네 장까지 첨부할 수 있어요."
            return
        }
        var staged: [Attachment] = []
        do {
            for url in urls {
                let scoped = url.startAccessingSecurityScopedResource()
                defer { if scoped { url.stopAccessingSecurityScopedResource() } }
                let values = try url.resourceValues(forKeys: [.fileSizeKey, .contentTypeKey])
                guard let size = values.fileSize, (1...10_485_760).contains(size),
                    let type = values.contentType, type.conforms(to: .image),
                    let mime = type.preferredMIMEType
                else {
                    throw ConversationInputError.invalidImage
                }
                let file = Attachment(
                    id: UUID().uuidString, name: url.lastPathComponent,
                    mime: mime, remoteID: nil)
                try FileManager.default.copyItem(at: url, to: file.localURL)
                staged.append(file)
            }
            if draftIsOutgoing { draft = Draft() }
            retryOperation = nil
            draft.key = UUID().uuidString.lowercased()
            draft.files += staged
        } catch {
            staged.forEach { $0.discardLocalCopy() }
            failure = error.localizedDescription
        }
    }

    func send() {
        guard canSend else { return }
        transmit(draft)
    }

    func retryOutgoing(_ id: String) {
        guard loaded, !busy, !cooldown, !store.sending,
              let item = outgoing.first(where: { $0.id == id }),
              item.failure != nil, item.retryable else { return }
        transmit(item.snapshot)
    }

    private func transmit(_ snapshot: Draft) {
        store.sending = true
        if let index = store.outgoing.firstIndex(where: { $0.id == snapshot.key }) {
            store.outgoing[index].failure = nil
        } else {
            store.outgoing.append(Outgoing(snapshot: snapshot))
        }
        run(outgoingID: snapshot.key) { [weak self] in
            guard let self else { return }
            var ids: [String] = []
            for file in snapshot.files {
                try Task.checkCancellation()
                if let remoteID = file.remoteID {
                    ids.append(remoteID)
                    continue
                }
                let bytes = try Data(contentsOf: file.localURL, options: .mappedIfSafe)
                let remoteID = try await self.repository.upload(
                    name: file.name,
                    contentType: file.mime, data: bytes)
                try Task.checkCancellation()
                if let index = self.draft.files.firstIndex(where: { $0.id == file.id }) {
                    self.draft.files[index].remoteID = remoteID
                }
                if let row = self.store.outgoing.firstIndex(where: { $0.id == snapshot.key }),
                   let index = self.store.outgoing[row].files.firstIndex(where: { $0.id == file.id }) {
                    self.store.outgoing[row].snapshot.files[index].remoteID = remoteID
                }
                ids.append(remoteID)
            }
            try Task.checkCancellation()
            try await self.repository.perform(
                .create(
                    key: snapshot.key, content: snapshot.text,
                    files: ids, reply: snapshot.reply,
                    mentions: (snapshot.mentions ?? [:])
                        .filter { snapshot.text.contains("@" + $0.value) }.keys.sorted()),
                thread: self.threadID)
            try Task.checkCancellation()
            if self.draft.key == snapshot.key {
                self.draft = Draft()
            }
            self.store.removeOutgoing(snapshot.key)
            await self.refresh()
        }
    }

    func perform(_ command: ThreadConversationCommand) {
        guard loaded else { return }
        run { [weak self] in
            guard let self else { return }
            try await self.repository.perform(command, thread: self.threadID)
            await self.refresh()
        }
    }

    func retry() {
        guard canRetry else { return }
        if loaded, let retryOperation {
            run(retryOperation)
        } else if loaded, let item = outgoing.first(where: { $0.id == draft.key && $0.failure != nil }) {
            retryOutgoing(item.id)
        } else {
            Task { await refresh() }
        }
    }

    func stop() {
        summary.close()
        retryOperation = nil
        revision += 1
        operation?.cancel()
    }

    private func revokeAccessIfNeeded(_ error: Error) -> Bool {
        if case ThreadConversationRejection.denied = error {
            for window in store.windows.allObjects { window.revokeAccess(error) }
            return true
        }
        if error is CancellationError {
            revokeAccess(error)
            return true
        }
        return false
    }

    private func revokeAccess(_ error: Error) {
        stop()
        accessRevoked = true
        for item in outgoing { store.removeOutgoing(item.id) }
        messages = []
        cursor = nil
        readID = nil
        pages = 1
        loaded = false
        canRetry = false
        failure = error.localizedDescription
    }

    private func run(outgoingID: String? = nil, _ work: @escaping @MainActor () async throws -> Void) {
        guard !busy && !cooldown else { return }
        busy = true
        failure = nil
        canRetry = true
        retryOperation = nil
        operation = Task {
            defer {
                if let outgoingID {
                    store.sending = false
                    if let item = outgoing.first(where: { $0.id == outgoingID }), item.failure == nil {
                        store.removeOutgoing(outgoingID)
                    }
                }
                busy = false
                operation = nil
            }
            do {
                // Fresh membership is required before preparing any attachment or command.
                do {
                    _ = try await repository.history(thread: threadID, before: nil)
                } catch {
                    guard !Task.isCancelled, !revokeAccessIfNeeded(error) else { return }
                    throw error
                }
                try Task.checkCancellation()
                guard loaded else { return }
                try await work()
            } catch {
                if !Task.isCancelled {
                    if let outgoingID,
                       let row = store.outgoing.firstIndex(where: { $0.id == outgoingID }) {
                        store.outgoing[row].failure = error.localizedDescription
                        if case ThreadConversationRejection.commandDenied = error {
                            store.outgoing[row].retryable = false
                        }
                    } else {
                        failure = error.localizedDescription
                    }
                    switch error {
                    case ThreadConversationRejection.rateLimited:
                        retryOperation = outgoingID == nil ? work : nil
                        cooldown = true
                        try? await Task.sleep(for: .seconds(3))
                        cooldown = false
                    case ThreadConversationRejection.denied:
                        _ = revokeAccessIfNeeded(error)
                    case ThreadConversationRejection.commandDenied:
                        canRetry = false
                    case is CancellationError:
                        revokeAccess(error)
                    default:
                        retryOperation = outgoingID == nil ? work : nil
                    }
                }
            }
        }
    }

    enum AccessEnd: LocalizedError, Equatable {
        case membership(CommunityThread)
        case denied
        case deleted

        var errorDescription: String? {
            switch self {
            case .membership(let detail) where detail.membershipState == "KICKED":
                "이 스레드에서 내보내졌어요."
            case .membership, .denied: "이 스레드에 참여할 권한이 없어요."
            case .deleted: "삭제된 스레드예요."
            }
        }
    }

    @MainActor @Observable
    final class WindowStore {
        private(set) var accessEnd: AccessEnd?
        var endedDetail: CommunityThread? {
            if case .membership(let detail) = accessEnd { return detail }
            return nil
        }
        private let threadID: String
        // Separate UserDefaults instances can refer to the same persistent suite.
        private static let stores = NSMapTable<NSString, WindowStore>.strongToWeakObjects()
        private let defaults: UserDefaults
        private let key: String
        fileprivate let windows = NSHashTable<ThreadConversationModel>.weakObjects()
        fileprivate var outgoing: [Outgoing] = []
        fileprivate func removeOutgoing(_ id: String) {
            guard let index = outgoing.firstIndex(where: { $0.id == id }) else { return }
            let files = outgoing.remove(at: index).files
            for file in files where !draft.files.contains(where: { $0.id == file.id })
                && !outgoing.contains(where: { $0.files.contains(where: { $0.id == file.id }) }) {
                file.discardLocalCopy()
            }
        }

        isolated deinit {
            // The persisted draft owns its files after the last window closes.
            for item in outgoing { removeOutgoing(item.id) }
        }

        fileprivate var sending = false
        fileprivate var draft: Draft {
            didSet {
                if draft.text.isEmpty, draft.reply == nil, draft.files.isEmpty {
                    defaults.removeObject(forKey: key)
                } else if let data = try? JSONEncoder().encode(draft) {
                    defaults.set(data, forKey: key)
                }
            }
        }

        func refreshDetail(
            using fetch: (String) async throws -> CommunityThread
        ) async throws -> CommunityThread {
            do {
                let detail = try await fetch(threadID)
                try Task.checkCancellation()
                receive(detail)
                switch accessEnd {
                case .denied: throw ThreadDetailError.accessDenied
                case .deleted: throw ThreadDetailError.deleted
                case .membership(let ended): return ended
                case nil: return detail
                }
            } catch let error as ThreadDetailError {
                try Task.checkCancellation()
                switch error {
                case .accessDenied: endAccess(.denied)
                case .deleted: endAccess(.deleted)
                }
                throw error
            }
        }

        func receive(_ detail: CommunityThread) {
            guard detail.id == threadID else { return }
            switch detail.membershipState {
            case "KICKED", "LEFT": endAccess(.membership(detail))
            case "KICKED_ACKNOWLEDGED": endAccess(.denied)
            default: break
            }
        }

        private func endAccess(_ end: AccessEnd) {
            guard accessEnd != end, accessEnd != .deleted else { return }
            if case .membership(let newDetail) = end, let accessEnd {
                guard case .membership(let previous) = accessEnd,
                      previous.membershipState == "LEFT", newDetail.membershipState == "KICKED"
                else { return }
            }
            accessEnd = end
            for item in outgoing { removeOutgoing(item.id) }
            for window in windows.allObjects { window.revokeAccess(end) }
            let files = draft.files
            draft = Draft()
            files.forEach { $0.discardLocalCopy() }
        }

        static func shared(
            defaults: UserDefaults, accountID: String, threadID: String
        ) -> WindowStore {
            let key = "community.conversation.\(accountID).\(threadID)"
            let suiteKey = "community.conversation.storageID"
            let suite: String
            if let stored = defaults.string(forKey: suiteKey) {
                suite = stored
            } else {
                suite = UUID().uuidString
                defaults.set(suite, forKey: suiteKey)
            }
            let identity = (suite + "." + key) as NSString
            if let existing = stores.object(forKey: identity) { return existing }
            let store = WindowStore(defaults: defaults, key: key, threadID: threadID)
            stores.setObject(store, forKey: identity)
            return store
        }

        private init(defaults: UserDefaults, key: String, threadID: String) {
            self.threadID = threadID
            self.defaults = defaults
            self.key = key
            draft = defaults.data(forKey: key).flatMap {
                try? JSONDecoder().decode(Draft.self, from: $0)
            } ?? Draft()
        }
    }

    struct Attachment: Identifiable, Codable {
        let id: String
        let name: String
        let mime: String
        var remoteID: String?

        var localURL: URL {
            FileManager.default.temporaryDirectory.appending(path: "umc-thread-photo-" + id)
        }

        func discardLocalCopy() {
            guard UUID(uuidString: id) != nil else { return }
            try? FileManager.default.removeItem(at: localURL)
        }
    }

    fileprivate struct Draft: Codable {
        var key = UUID().uuidString.lowercased()
        var text = ""
        var reply: String?
        var files: [Attachment] = []
        var mentions: [String: String]?
    }

    private enum ConversationInputError: LocalizedError {
        case invalidImage
        var errorDescription: String? { "10MB 이하의 사진을 선택해 주세요." }
    }
}
