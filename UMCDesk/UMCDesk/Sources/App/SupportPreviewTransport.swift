//  SupportPreviewTransport.swift
//  UMCDesk
//
//  Created by euijjang97 on 11/28/26.
//

import Foundation
import Observation

/// Simulates responses inside one sample session. No operation leaves this process.
@Observable final class SupportPreviewTransport {
    enum Outcome: String, CaseIterable {
        case success = "성공"
        case rejected = "쓰기 실패"
        case uncertain = "결과 확인 필요"
        case lostAfterApply = "응답 유실 · 조회로 반영 확인"
        case lostBeforeApply = "응답 유실 · 조회로 미반영 확인"
        case refreshFailed = "쓰기 성공 · 조회 실패"
        case attachmentFailed = "접수 성공 · 첨부 실패"
    }

    enum Receipt: Equatable {
        case sending, failed, uncertain, success, refreshFailed, attachmentFailed
        var acknowledged: Bool {
            self == .success || self == .refreshFailed || self == .attachmentFailed
        }
    }

    struct Key: Hashable {
        let scope: String
        let action: String
        let isOperator: Bool
    }

    static let createKey = Key(scope: "my-inquiries", action: "문의 보내기", isOperator: false)
    private var payloads: [Key: [String]] = [:]
    private(set) var submittedTickets: [UUID: UUID] = [:]

    func rememberTicket(_ ticket: UUID, request: UUID) { submittedTickets[request] = ticket }

    func requestID(for key: Key, payload: [String]) -> UUID {
        if state(key) == .failed, payloads[key] == payload, let original = requests[key] {
            return original
        }
        return UUID()
    }

    struct ReplyInput: Equatable {
        var text = ""
        var attachment = false
    }

    /// Editing either field starts a new local draft, even when its values later match again.
    struct ReplyDraft {
        var input = ReplyInput() {
            didSet { if input != oldValue { request = nil } }
        }
        var request: UUID?

        mutating func acknowledge(_ id: UUID, receipt: Receipt?) -> Bool {
            guard request == id, receipt?.acknowledged == true else { return false }
            self = ReplyDraft()
            return true
        }
    }

    private(set) var requests: [Key: UUID] = [:]
    private var authoritative: [UUID: Receipt] = [:]
    private(set) var pendingReplies: [Key: ReplyInput] = [:]
    var pendingFAQs: [Key: SupportDraft] = [:]

    func state(_ key: Key) -> Receipt? {
        requests[key].flatMap { receipts[$0] }
    }

    func blocked(_ key: Key) -> Bool {
        state(key) == .sending || state(key) == .uncertain
    }

    enum Access: String, CaseIterable {
        case checking = "권한 확인 중"
        case granted = "운영 허용"
        case denied = "운영 권한 없음"
    }

    enum Read: Equatable { case loading, refreshing, ready, failed }
    var access = Access.granted {
        didSet {
            guard oldValue != access else { return }
            authorizationGeneration += 1
            if access != .granted {
                pendingReplies = pendingReplies.filter { !$0.key.isOperator }
                pendingFAQs.removeAll()
                payloads = payloads.filter { !$0.key.isOperator }
            }
        }
    }
    var nextWrite = Outcome.success
    var nextReadFails = false
    private(set) var read = Read.ready
    private(set) var hasSnapshot = true
    private var readRequest = 0
    private var authorizationGeneration = 0
    private(set) var receipts: [UUID: Receipt] = [:]

    @MainActor func reload(verifying key: Key? = nil) async {
        let submitted = key.flatMap { requests[$0] }
        readRequest += 1
        let request = readRequest
        let failure = nextReadFails
        nextReadFails = false
        read = hasSnapshot ? .refreshing : .loading
        try? await Task.sleep(for: .milliseconds(120))
        guard request == readRequest, !Task.isCancelled else { return }
        read = failure ? .failed : .ready
        guard !failure else { return }
        hasSnapshot = true
        if let key, let submitted, requests[key] == submitted, receipts[submitted] == .uncertain,
            !key.isOperator || access == .granted, let actual = authoritative[submitted]
        {
            receipts[submitted] = actual
            if actual == .success { pendingFAQs[key] = nil }
        }
    }

    func simulateFailedRead(hasSnapshot: Bool = false) {
        read = .failed
        self.hasSnapshot = hasSnapshot
    }

    func prepareInitialRead() {
        hasSnapshot = false
        read = .loading
    }

    /// Each user intent has one ID, including retries after a confirmed rejection.
    @MainActor func send(
        id: UUID, key: Key? = nil, payload: [String] = [], reply: ReplyInput? = nil,
        retrying expected: UUID? = nil,
        requiresOperator: Bool = false, hasAttachment: Bool = false,
        apply: (Bool) -> Bool
    ) async -> Receipt {
        if let expected, let key {
            guard requests[key] == expected, id == expected, state(key) == .failed,
                payloads[key] == payload
            else { return .failed }
        }
        if let key, blocked(key), let result = state(key) { return result }
        if let existing = receipts[id], existing != .failed { return existing }
        guard !requiresOperator || access == .granted else { return .failed }
        if let key {
            if let reply { pendingReplies[key] = reply }
            requests[key] = id
            payloads[key] = payload
        }
        let generation = authorizationGeneration
        let outcome = nextWrite
        nextWrite = .success
        receipts[id] = .sending
        try? await Task.sleep(for: .milliseconds(120))
        guard !Task.isCancelled,
            !requiresOperator || (access == .granted && generation == authorizationGeneration)
        else {
            receipts[id] = .failed
            return .failed
        }
        let result: Receipt
        switch outcome {
        case .rejected: result = .failed
        case .uncertain: result = .uncertain
        case .lostBeforeApply:
            authoritative[id] = .failed
            result = .uncertain
        case .lostAfterApply:
            authoritative[id] = apply(true) ? .success : .failed
            result = .uncertain
        case .success, .refreshFailed, .attachmentFailed:
            let failedAttachment = hasAttachment && outcome == .attachmentFailed
            if apply(!failedAttachment) {
                if outcome == .refreshFailed { read = .failed }
                result =
                    failedAttachment
                    ? .attachmentFailed : (outcome == .refreshFailed ? .refreshFailed : .success)
            } else {
                result = .failed
            }
        }
        receipts[id] = result
        return result
    }
}

/// One navigation decision per workspace. Other windows receive their own gate.
@MainActor @Observable final class SupportExitGate {
    var hasChanges = false
    var sending = false
    private var pending: (() -> Void)?
    var needsConfirmation: Bool { pending != nil }

    func request(_ action: @escaping () -> Void) {
        guard !sending, pending == nil else { return }
        if hasChanges { pending = action } else { action() }
    }

    func stay() { pending = nil }
    func discard() {
        let action = pending
        pending = nil
        hasChanges = false
        action?()
    }
}
