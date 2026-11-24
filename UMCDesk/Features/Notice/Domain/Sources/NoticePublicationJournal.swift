//  NoticePublicationJournal.swift
//  NoticeDomain
//
//  Created by euijjang97 on 11/23/26.

import CryptoKit
import Darwin
import Foundation

public struct NoticePublicationInput: Codable, Sendable {
    public let gisu: String
    public let draft: NoticeDraft
    public let files: [URL]
    public let links: [String]
    public let poll: NoticePollDraft?

    public init(
        gisu: String, draft: NoticeDraft, files: [URL], links: [String], poll: NoticePollDraft?
    ) {
        self.gisu = gisu
        self.draft = draft
        self.files = files
        self.links = links
        self.poll = poll
    }
}

struct NoticePublicationRecord: Codable {
    let input: NoticePublicationInput
    let previousIDs: Set<String>
    let noticeID: String?
    let needsListCheck: Bool
    let needsPollCheck: Bool
    let uploaded: [URL: String]
    let imagesAttached: Bool
    let linksAttached: Bool
}

/// 작성 시트를 소유한 프로세스만 이 계정의 복구 기록과 사진을 변경할 수 있다.
public final class NoticePublicationJournal: Sendable {
    private let directory: URL
    private let lock: Int32
    private var record: URL { directory.appending(path: "attempt.json") }
    private var photos: URL { directory.appending(path: "photos", directoryHint: .isDirectory) }

    public init(accountID: String, environment: URL, root: URL? = nil) throws {
        let base =
            try root
            ?? FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask, appropriateFor: nil, create: true
            )
            .appending(path: "UMCDesk/NoticePublications", directoryHint: .isDirectory)
        let key = try JSONEncoder().encode([environment.absoluteString, accountID])
        let name = SHA256.hash(data: key).map { String(format: "%02x", $0) }.joined()
        directory = base.appending(path: name, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(
            at: directory, withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700])
        let descriptor = open(
            directory.appending(path: "writer.lock").path, O_CREAT | O_RDWR | O_CLOEXEC, 0o600)
        guard descriptor >= 0 else { throw POSIXError(.EACCES) }
        guard flock(descriptor, LOCK_EX | LOCK_NB) == 0 else {
            close(descriptor)
            throw NoticeRequestFailure.rejected("다른 창에서 이 계정의 공지를 작성 중입니다.")
        }
        lock = descriptor
    }

    deinit { close(lock) }

    func read() throws -> NoticePublicationRecord? {
        do {
            return try JSONDecoder().decode(
                NoticePublicationRecord.self, from: Data(contentsOf: record))
        } catch let error as CocoaError where error.code == .fileReadNoSuchFile { return nil }
    }

    func write(_ value: NoticePublicationRecord) throws {
        try JSONEncoder().encode(value).write(to: record, options: .atomic)
    }

    func clear() throws {
        if FileManager.default.fileExists(atPath: record.path) {
            try FileManager.default.removeItem(at: record)
        }
        if FileManager.default.fileExists(atPath: photos.path) {
            try FileManager.default.removeItem(at: photos)
        }
    }

    /// 선택 권한이 살아 있는 동안 앱 컨테이너에 독립 사본을 만든다.
    func stage(_ input: NoticePublicationInput, uploaded: [URL: String]) throws
        -> NoticePublicationInput
    {
        let manager = FileManager.default
        let copies = try input.files.map { file in
            if file.deletingLastPathComponent().deletingLastPathComponent().standardizedFileURL
                .path == photos.standardizedFileURL.path
            {
                guard uploaded[file] != nil || manager.isReadableFile(atPath: file.path) else {
                    throw NoticeRequestFailure.rejected(
                        "‘" + file.lastPathComponent + "’ 사진을 제거하고 다시 선택해 주세요.")
                }
                return file
            }
            let scoped = file.startAccessingSecurityScopedResource()
            defer { if scoped { file.stopAccessingSecurityScopedResource() } }
            let info = try file.resourceValues(forKeys: [
                .fileSizeKey, .isRegularFileKey, .isSymbolicLinkKey,
            ])
            guard info.isRegularFile == true, info.isSymbolicLink != true,
                (1...10_485_760).contains(info.fileSize ?? 0)
            else {
                throw NoticeRequestFailure.rejected("10MB 이하의 사진 파일을 다시 선택해 주세요.")
            }
            let folder = photos.appending(path: UUID().uuidString, directoryHint: .isDirectory)
            try manager.createDirectory(at: folder, withIntermediateDirectories: true)
            let copy = folder.appending(path: file.lastPathComponent)
            try manager.copyItem(at: file, to: copy)
            return copy
        }
        return NoticePublicationInput(
            gisu: input.gisu, draft: input.draft,
            files: copies, links: input.links, poll: input.poll)
    }
}
