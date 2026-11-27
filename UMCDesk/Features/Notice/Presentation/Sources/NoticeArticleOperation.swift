//  NoticeArticleOperation.swift
//  NoticePresentation
//
//  Created by euijjang97 on 11/27/26.

import Foundation
import NoticeDomain
import Observation

/// Owns the shared in-flight guard and distinguishes a failed action from a failed read.
@MainActor
@Observable
final class NoticeArticleOperation {
    private(set) var isBusy = false
    private(set) var failure: NoticeArticleFailure?

    func delete(
        repository: any NoticeRepository, id: String,
        hasContent: () -> Bool, onAccessLost: () -> Void,
        onChanged: () -> Void, onDelete: () -> Void
    ) async {
        await perform(action: .delete, hasContent: hasContent, onAccessLost: onAccessLost) {
            try await repository.delete(id: id)
            onChanged()
            onDelete()
        }
    }

    func perform(
        action: NoticeArticleFailure.Action = .load,
        hasContent: () -> Bool, onAccessLost: () -> Void,
        _ operation: () async throws -> Void
    ) async {
        guard !isBusy else { return }
        isBusy = true
        failure = nil
        defer { isBusy = false }
        do {
            try await operation()
        } catch NoticeRequestFailure.accessDenied {
            if !Task.isCancelled { onAccessLost() }
        } catch {
            if !Task.isCancelled {
                let loaded = hasContent()
                failure = NoticeArticleFailure(
                    message: error.localizedDescription, hasContent: loaded,
                    action: loaded ? action : .load)
            }
        }
    }
}
