//
//  ThreadManagementPeopleModel.swift
//  CommunityPresentation
//
//  Created by euijjang97 on 11/23/26.
//

import CommunityDomain
import Foundation
import Observation

enum ThreadManagementOperation: String, Identifiable {
    case kick = "내보내기"
    case promote = "관리자 지정"
    case demote = "관리자 해제"
    case transfer = "개설자 위임"
    var id: Self { self }

    func action(for memberID: String) -> ThreadManagementAction {
        switch self {
        case .kick: .kick(memberID: memberID)
        case .promote: .role(memberID: memberID, .admin)
        case .demote: .role(memberID: memberID, .member)
        case .transfer: .role(memberID: memberID, .owner)
        }
    }
}

@MainActor @Observable
final class ThreadManagementPeopleModel {
    private(set) var rows: [ThreadManagementPerson] = []
    private(set) var currentID: String?
    private(set) var cursor: String?
    private(set) var loading = false
    private(set) var failure: String?
    private(set) var failed: [ThreadManagementPerson] = []
    private(set) var succeeded: [ThreadManagementPerson] = []
    private(set) var lastAction: ThreadManagementOperation?
    var selecting = false
    var selection: [String: ThreadManagementPerson] = [:]
    var showsFailure = false
    private(set) var completion: String?
    var operationError: String?
    @ObservationIgnored private var requestID = UUID()

    func toggleSelectionMode() {
        selecting.toggle()
        selection.removeAll()
        completion = nil
    }

    func load(threadID: String, mode: ThreadManagementPeopleMode, query: String,
              offset: String?, needsIdentity: Bool, repository: any ThreadManagementRepository)
        async {
        let request = UUID()
        requestID = request
        loading = true
        failure = nil
        if offset == nil {
            rows = []
            cursor = nil
        }
        defer {
            if requestID == request { loading = false }
        }
        do {
            if currentID == nil && mode != .invite && needsIdentity {
                currentID = try await repository.currentMemberID()
            }
            if !query.isEmpty && offset == nil { try await Task.sleep(for: .milliseconds(180)) }
            let page = try await repository.people(threadID: threadID, invitable: mode == .invite,
                                                   query: query, offset: offset)
            try Task.checkCancellation()
            guard requestID == request else { return }
            var ids = Set(rows.map(\.memberId))
            rows += page.items.filter { ids.insert($0.memberId).inserted }
            cursor = page.nextOffset != offset ? page.nextOffset : nil
        } catch {
            if !Task.isCancelled, requestID == request { failure = error.localizedDescription }
        }
    }

    func apply(_ operation: ThreadManagementOperation, targets: [ThreadManagementPerson],
               repository: any ThreadManagementRepository, threadID: String) async -> Bool {
        succeeded = []
        lastAction = operation
        return await perform(operation, targets: targets, repository: repository,
                             threadID: threadID)
    }

    func retryFailures(repository: any ThreadManagementRepository, threadID: String)
        async -> Bool {
        guard showsFailure, let lastAction, !failed.isEmpty else { return false }
        return await perform(lastAction, targets: failed, repository: repository,
                             threadID: threadID)
    }

    private func perform(_ operation: ThreadManagementOperation, targets: [ThreadManagementPerson],
                         repository: any ThreadManagementRepository, threadID: String)
        async -> Bool {
        guard !targets.isEmpty else { return false }
        completion = nil
        operationError = nil
        var completed: [ThreadManagementPerson] = []
        var remaining: [ThreadManagementPerson] = []
        for person in targets {
            do {
                try await repository.apply(operation.action(for: person.memberId),
                                           threadID: threadID)
                completed.append(person)
            } catch {
                remaining.append(person)
                operationError = error.localizedDescription
            }
        }
        succeeded += completed
        failed = remaining
        selection.removeAll()
        selecting = false
        showsFailure = !failed.isEmpty
        if !showsFailure {
            let subject = completed.count == 1 ? "\(completed[0].name)님" : "\(completed.count)명"
            completion = operation == .kick
                ? subject + "을 내보냈어요."
                : subject + " · " + operation.rawValue + " 완료"
        }
        return !completed.isEmpty
    }
}
