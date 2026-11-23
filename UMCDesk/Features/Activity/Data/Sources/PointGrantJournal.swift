//  PointGrantJournal.swift
//  ActivityData
//
//  Created by euijjang97 on 11/23/26.
//

import ActivityDomain
import CryptoKit
import Darwin
import Foundation

enum PointJournalError: LocalizedError {
    case unresolved, reusedID, manuallyReviewed

    var errorDescription: String? {
        switch self {
        case .unresolved: "이 구성원에게 확인 중인 지급이 있어요. 이전 지급을 먼저 확인해 주세요."
        case .reusedID: "지급 요청의 내용이 변경됐어요."
        case .manuallyReviewed: "이미 수동 확인을 마친 요청이에요."
        }
    }
}

struct PointGrantJournal: Sendable {
    enum Status: String, Codable { case pending, recorded, reviewed }
    struct Entry: Codable {
        let intent: PointGrantIntent
        var baseline: Set<String>
        var status: Status
    }

    private let directory: URL

    init(baseURL: URL, memberID: String, directory: URL?) {
        let root =
            directory ?? URL.applicationSupportDirectory.appending(path: "UMCDesk/PointGrants")
        var environment = URLComponents(url: baseURL, resolvingAgainstBaseURL: true)
        if var parts = environment {
            parts.scheme = parts.scheme?.lowercased()
            parts.host = parts.host?.lowercased()
            if (parts.scheme == "https" && parts.port == 443)
                || (parts.scheme == "http" && parts.port == 80)
            {
                parts.port = nil
            }
            while parts.percentEncodedPath.last == "/" { parts.percentEncodedPath.removeLast() }
            environment = parts
        }
        let scope = [environment?.string ?? baseURL.absoluteString, memberID].map {
            "\($0.utf8.count):\($0)"
        }.joined()
        let digest = SHA256.hash(data: Data(scope.utf8)).map { String(format: "%02x", $0) }
            .joined()
        self.directory = root.appending(path: digest)
    }

    func pending(_ challenger: String) throws -> PointGrantIntent? {
        try access { entries in
            entries.first { $0.intent.challengerID == challenger && $0.status == .pending }?.intent
        }
    }

    func lookup(_ intent: PointGrantIntent) throws -> Entry? {
        try access { entries in try existing(intent, in: entries) }
    }

    /// Only the caller which atomically inserts this intent may issue its POST.
    func reserve(_ intent: PointGrantIntent, baseline: Set<String>) throws -> Entry? {
        try access { entries in
            if let prior = try existing(intent, in: entries) { return prior }
            entries.append(Entry(intent: intent, baseline: baseline, status: .pending))
            try save(entries)
            return nil
        }
    }

    private func existing(_ intent: PointGrantIntent, in entries: [Entry]) throws -> Entry? {
        if let prior = entries.first(where: { $0.intent.id == intent.id }) {
            guard prior.intent == intent else { throw PointJournalError.reusedID }
            return prior
        }
        if entries.contains(where: {
            $0.intent.challengerID == intent.challengerID && $0.status == .pending
        }) {
            throw PointJournalError.unresolved
        }
        return nil
    }

    func close(_ id: UUID, as status: Status?) throws {
        try access { entries in
            guard let index = entries.firstIndex(where: { $0.intent.id == id }),
                entries[index].status == .pending
            else { return }
            if let status {
                entries[index].status = status
                entries[index].baseline = []
            } else {
                entries.remove(at: index)
            }
            try save(entries)
        }
    }

    private func save(_ entries: [Entry]) throws {
        try JSONEncoder().encode(entries).write(
            to: directory.appending(path: "journal.json"), options: .atomic)
    }

    private func access<T>(_ action: (inout [Entry]) throws -> T) throws -> T {
        try FileManager.default.createDirectory(
            at: directory, withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700])
        let fd = open(directory.appending(path: "journal.lock").path, O_CREAT | O_RDWR, 0o600)
        guard fd >= 0 else { throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO) }
        defer { Darwin.close(fd) }
        guard flock(fd, LOCK_EX) == 0 else {
            throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
        }
        var entries: [Entry]
        do {
            let data = try Data(contentsOf: directory.appending(path: "journal.json"))
            entries = try JSONDecoder().decode([Entry].self, from: data)
        } catch let error as CocoaError where error.code == .fileReadNoSuchFile {
            entries = []
        }
        return try action(&entries)
    }
}
