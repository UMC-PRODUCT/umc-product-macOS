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
        case refreshFailed = "쓰기 성공 · 조회 실패"
        case attachmentFailed = "접수 성공 · 첨부 실패"
    }

    enum Receipt: Equatable {
        case sending, failed, uncertain, success, refreshFailed, attachmentFailed
        var acknowledged: Bool {
            self == .success || self == .refreshFailed || self == .attachmentFailed
        }
    }

    enum Access: String, CaseIterable {
        case checking = "권한 확인 중"
        case granted = "운영 허용"
        case denied = "운영 권한 없음"
    }

    enum Read: Equatable { case loading, refreshing, ready, failed }
    var access = Access.granted {
        didSet { if oldValue != access { authorizationGeneration += 1 } }
    }
    var nextWrite = Outcome.success
    var nextReadFails = false
    private(set) var read = Read.ready
    private(set) var hasSnapshot = true
    private var readRequest = 0
    private var authorizationGeneration = 0
    private(set) var receipts: [UUID: Receipt] = [:]

    @MainActor func reload() async {
        readRequest += 1
        let request = readRequest
        let failure = nextReadFails
        nextReadFails = false
        read = hasSnapshot ? .refreshing : .loading
        try? await Task.sleep(for: .milliseconds(120))
        guard request == readRequest, !Task.isCancelled else { return }
        read = failure ? .failed : .ready
        if !failure { hasSnapshot = true }
    }

    func simulateFailedRead() {
        read = .failed
        hasSnapshot = false
    }

    func prepareInitialRead() {
        hasSnapshot = false
        read = .loading
    }

    /// Each user intent has one ID, including retries after a confirmed rejection.
    @MainActor func send(
        id: UUID, requiresOperator: Bool = false, hasAttachment: Bool = false,
        apply: (Bool) -> Bool
    ) async -> Receipt {
        if let existing = receipts[id], existing != .failed { return existing }
        guard !requiresOperator || access == .granted else { return .failed }
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
