//
//  NoticeDomain.swift
//  NoticeDomain
//
//  Created by euijjang97 on 11/23/26.
//

import Foundation
import Observation
import UMCFoundation

public struct NoticeAuthor: Codable, Sendable {
    public let name: String?
    public let nickname: String?
    public let organizationName: String?

    public init(
        name: String?,
        nickname: String?,
        organizationName: String?
    ) {
        self.name = name
        self.nickname = nickname
        self.organizationName = organizationName
    }

    private enum CodingKeys: CodingKey {
        case name
        case nickname
        case organizationName
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        name = try values.decodeIfPresent(String.self, forKey: .name)
        nickname = try values.decodeIfPresent(String.self, forKey: .nickname)
        organizationName = try values.decodeIfPresent(String.self, forKey: .organizationName)
    }

    public func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encodeIfPresent(name, forKey: .name)
        try values.encodeIfPresent(nickname, forKey: .nickname)
        try values.encodeIfPresent(organizationName, forKey: .organizationName)
    }
}

public struct NoticeAudience: Codable, Sendable {
    public let targetGisuId: String?
    public let targetChapterId: String?
    public let targetSchoolId: String?
    public let targetNoticeTab: String
    public let targetParts: [String]?

    public init(
        targetGisuId: String?,
        targetChapterId: String?,
        targetSchoolId: String?,
        targetNoticeTab: String,
        targetParts: [String]?
    ) {
        self.targetGisuId = targetGisuId
        self.targetChapterId = targetChapterId
        self.targetSchoolId = targetSchoolId
        self.targetNoticeTab = targetNoticeTab
        self.targetParts = targetParts
    }

    private enum CodingKeys: CodingKey {
        case targetGisuId
        case targetChapterId
        case targetSchoolId
        case targetNoticeTab
        case targetParts
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        targetGisuId = try values.decodeFlexibleStringIfPresent(forKey: .targetGisuId)
        targetChapterId = try values.decodeFlexibleStringIfPresent(forKey: .targetChapterId)
        targetSchoolId = try values.decodeFlexibleStringIfPresent(forKey: .targetSchoolId)
        targetNoticeTab = try values.decode(String.self, forKey: .targetNoticeTab)
        targetParts = try values.decodeIfPresent([String].self, forKey: .targetParts)
    }

    public func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encodeIfPresent(targetGisuId, forKey: .targetGisuId)
        try values.encodeIfPresent(targetChapterId, forKey: .targetChapterId)
        try values.encodeIfPresent(targetSchoolId, forKey: .targetSchoolId)
        try values.encode(targetNoticeTab, forKey: .targetNoticeTab)
        try values.encodeIfPresent(targetParts, forKey: .targetParts)
    }
}

public struct NoticeAttachment: Codable, Sendable, Identifiable {
    public let id: String
    public let fileId: String?
    public let url: String

    public init(
        id: String,
        fileId: String? = nil,
        url: String
    ) {
        self.id = id
        self.fileId = fileId
        self.url = url
    }

    private enum CodingKeys: CodingKey {
        case id
        case fileId
        case url
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decodeFlexibleString(forKey: .id)
        fileId = try values.decodeIfPresent(String.self, forKey: .fileId)
        url = try values.decode(String.self, forKey: .url)
    }

    public func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(id, forKey: .id)
        try values.encodeIfPresent(fileId, forKey: .fileId)
        try values.encode(url, forKey: .url)
    }
}

public struct NoticeVoteOption: Codable, Sendable {
    public let optionId: String
    public let content: String
    public let voteCount: String

    public init(
        optionId: String,
        content: String,
        voteCount: String
    ) {
        self.optionId = optionId
        self.content = content
        self.voteCount = voteCount
    }

    private enum CodingKeys: CodingKey {
        case optionId
        case content
        case voteCount
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        optionId = try values.decodeFlexibleString(forKey: .optionId)
        content = try values.decode(String.self, forKey: .content)
        voteCount = try values.decodeFlexibleString(forKey: .voteCount)
    }

    public func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(optionId, forKey: .optionId)
        try values.encode(content, forKey: .content)
        try values.encode(voteCount, forKey: .voteCount)
    }
}

public struct NoticeVote: Codable, Sendable {
    public let title: String
    public let isAnonymous: Bool
    public let allowMultipleChoice: Bool
    public let status: String
    public let endsAtExclusive: String
    public let totalParticipants: String
    public let options: [NoticeVoteOption]
    public let mySelectedOptionIds: [String]

    public init(
        title: String,
        isAnonymous: Bool,
        allowMultipleChoice: Bool,
        status: String,
        endsAtExclusive: String,
        totalParticipants: String,
        options: [NoticeVoteOption],
        mySelectedOptionIds: [String]
    ) {
        self.title = title
        self.isAnonymous = isAnonymous
        self.allowMultipleChoice = allowMultipleChoice
        self.status = status
        self.endsAtExclusive = endsAtExclusive
        self.totalParticipants = totalParticipants
        self.options = options
        self.mySelectedOptionIds = mySelectedOptionIds
    }

    private enum CodingKeys: CodingKey {
        case title
        case isAnonymous
        case allowMultipleChoice
        case status
        case endsAtExclusive
        case totalParticipants
        case options
        case mySelectedOptionIds
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        title = try values.decode(String.self, forKey: .title)
        isAnonymous = try values.decode(Bool.self, forKey: .isAnonymous)
        allowMultipleChoice = try values.decode(Bool.self, forKey: .allowMultipleChoice)
        status = try values.decode(String.self, forKey: .status)
        endsAtExclusive = try values.decode(String.self, forKey: .endsAtExclusive)
        totalParticipants = try values.decodeFlexibleString(forKey: .totalParticipants)
        options = try values.decode([NoticeVoteOption].self, forKey: .options)
        mySelectedOptionIds = values.decodeFlexibleStringArray(forKey: .mySelectedOptionIds)
    }

    public func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(title, forKey: .title)
        try values.encode(isAnonymous, forKey: .isAnonymous)
        try values.encode(allowMultipleChoice, forKey: .allowMultipleChoice)
        try values.encode(status, forKey: .status)
        try values.encode(endsAtExclusive, forKey: .endsAtExclusive)
        try values.encode(totalParticipants, forKey: .totalParticipants)
        try values.encode(options, forKey: .options)
        try values.encode(mySelectedOptionIds, forKey: .mySelectedOptionIds)
    }
}

public struct NoticeEntry: Codable, Sendable, Identifiable {
    public let id: String
    public let title: String
    public let content: String
    public let mustRead: Bool
    public let viewCount: String
    public let createdAt: String
    public let author: NoticeAuthor?
    public let targetInfo: NoticeAudience?
    public let hasImages: Bool?
    public let hasLinks: Bool?
    public let hasVote: Bool?
    public let images: [NoticeAttachment]?
    public let links: [NoticeAttachment]?
    public let vote: NoticeVote?

    public init(
        id: String,
        title: String,
        content: String,
        mustRead: Bool,
        viewCount: String,
        createdAt: String,
        author: NoticeAuthor?,
        targetInfo: NoticeAudience?,
        hasImages: Bool?,
        hasLinks: Bool?,
        hasVote: Bool?,
        images: [NoticeAttachment]?,
        links: [NoticeAttachment]?,
        vote: NoticeVote?
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.mustRead = mustRead
        self.viewCount = viewCount
        self.createdAt = createdAt
        self.author = author
        self.targetInfo = targetInfo
        self.hasImages = hasImages
        self.hasLinks = hasLinks
        self.hasVote = hasVote
        self.images = images
        self.links = links
        self.vote = vote
    }

    private enum CodingKeys: CodingKey {
        case id
        case title
        case content
        case mustRead
        case viewCount
        case createdAt
        case author
        case targetInfo
        case hasImages
        case hasLinks
        case hasVote
        case images
        case links
        case vote
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decodeFlexibleString(forKey: .id)
        title = try values.decode(String.self, forKey: .title)
        content = try values.decode(String.self, forKey: .content)
        mustRead = try values.decode(Bool.self, forKey: .mustRead)
        viewCount = try values.decodeFlexibleString(forKey: .viewCount)
        createdAt = try values.decode(String.self, forKey: .createdAt)
        author = try values.decodeIfPresent(NoticeAuthor.self, forKey: .author)
        targetInfo = try values.decodeIfPresent(NoticeAudience.self, forKey: .targetInfo)
        hasImages = try values.decodeIfPresent(Bool.self, forKey: .hasImages)
        hasLinks = try values.decodeIfPresent(Bool.self, forKey: .hasLinks)
        hasVote = try values.decodeIfPresent(Bool.self, forKey: .hasVote)
        images = try values.decodeIfPresent([NoticeAttachment].self, forKey: .images)
        links = try values.decodeIfPresent([NoticeAttachment].self, forKey: .links)
        vote = try values.decodeIfPresent(NoticeVote.self, forKey: .vote)
    }

    public func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(id, forKey: .id)
        try values.encode(title, forKey: .title)
        try values.encode(content, forKey: .content)
        try values.encode(mustRead, forKey: .mustRead)
        try values.encode(viewCount, forKey: .viewCount)
        try values.encode(createdAt, forKey: .createdAt)
        try values.encodeIfPresent(author, forKey: .author)
        try values.encodeIfPresent(targetInfo, forKey: .targetInfo)
        try values.encodeIfPresent(hasImages, forKey: .hasImages)
        try values.encodeIfPresent(hasLinks, forKey: .hasLinks)
        try values.encodeIfPresent(hasVote, forKey: .hasVote)
        try values.encodeIfPresent(images, forKey: .images)
        try values.encodeIfPresent(links, forKey: .links)
        try values.encodeIfPresent(vote, forKey: .vote)
    }
}

public struct NoticePage: Codable, Sendable {
    public let content: [NoticeEntry]
    public let hasNext: Bool

    public init(
        content: [NoticeEntry],
        hasNext: Bool
    ) {
        self.content = content
        self.hasNext = hasNext
    }

    private enum CodingKeys: CodingKey {
        case content
        case hasNext
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        content = try values.decode([NoticeEntry].self, forKey: .content)
        hasNext = try values.decode(Bool.self, forKey: .hasNext)
    }

    public func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(content, forKey: .content)
        try values.encode(hasNext, forKey: .hasNext)
    }
}

public struct NoticeReadCounts: Codable, Sendable {
    public let totalCount: String
    public let readCount: String
    public let unreadCount: String

    public init(
        totalCount: String,
        readCount: String,
        unreadCount: String
    ) {
        self.totalCount = totalCount
        self.readCount = readCount
        self.unreadCount = unreadCount
    }

    private enum CodingKeys: CodingKey {
        case totalCount
        case readCount
        case unreadCount
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        totalCount = try values.decodeFlexibleString(forKey: .totalCount)
        readCount = try values.decodeFlexibleString(forKey: .readCount)
        unreadCount = try values.decodeFlexibleString(forKey: .unreadCount)
    }

    public func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(totalCount, forKey: .totalCount)
        try values.encode(readCount, forKey: .readCount)
        try values.encode(unreadCount, forKey: .unreadCount)
    }
}

public struct NoticeReader: Codable, Sendable {
    public let challengerId: String
    public let name: String
    public let schoolName: String?

    public init(
        challengerId: String,
        name: String,
        schoolName: String?
    ) {
        self.challengerId = challengerId
        self.name = name
        self.schoolName = schoolName
    }

    private enum CodingKeys: CodingKey {
        case challengerId
        case name
        case schoolName
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        challengerId = try values.decodeFlexibleString(forKey: .challengerId)
        name = try values.decode(String.self, forKey: .name)
        schoolName = try values.decodeIfPresent(String.self, forKey: .schoolName)
    }

    public func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(challengerId, forKey: .challengerId)
        try values.encode(name, forKey: .name)
        try values.encodeIfPresent(schoolName, forKey: .schoolName)
    }
}

public struct NoticeReaders: Codable, Sendable {
    public let content: [NoticeReader]
    public let nextCursor: String?
    public let hasNext: Bool

    public init(
        content: [NoticeReader],
        nextCursor: String?,
        hasNext: Bool
    ) {
        self.content = content
        self.nextCursor = nextCursor
        self.hasNext = hasNext
    }

    private enum CodingKeys: CodingKey {
        case content
        case nextCursor
        case hasNext
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        content = try values.decode([NoticeReader].self, forKey: .content)
        nextCursor = try values.decodeFlexibleStringIfPresent(forKey: .nextCursor)
        hasNext = try values.decode(Bool.self, forKey: .hasNext)
    }

    public func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(content, forKey: .content)
        try values.encodeIfPresent(nextCursor, forKey: .nextCursor)
        try values.encode(hasNext, forKey: .hasNext)
    }
}

public struct NoticeDraft: Sendable {
    public var title = ""
    public var content = ""
    public var shouldNotify = false
    public var mustRead = false
    public var noticeTab = "CHALLENGER"
    public var chapterId: String?
    public var schoolId: String?
    public var parts: [String] = []

    public init() {}
}

public struct NoticePollDraft: Sendable {
    public var title = ""
    public var options = ["", ""]
    public var isAnonymous = true
    public var allowMultipleChoice = false
    public var endsAt = Date.now.addingTimeInterval(86400)

    public init() {}
}

public protocol NoticeRepository: Sendable {
    func activeGisu() async throws -> String
    func canCompose(gisu: String) async throws -> Bool
    func organization(gisu: String) async throws -> NoticeOrganization?
    func notices(gisu: String, tab: String, keyword: String, part: String?, page: Int) async throws
        -> NoticePage
    func detail(id: String) async throws -> NoticeEntry
    func create(_ draft: NoticeDraft, gisu: String) async throws -> String
    func attachLinks(_ links: [String], id: String) async throws
    func uploadImage(file: URL) async throws -> String
    func attachImages(_ files: [String], id: String) async throws
    func addPoll(_ poll: NoticePollDraft, id: String) async throws
    func vote(options: [String], replacing: Bool, id: String) async throws
    func permissions(id: String) async throws -> Set<String>
    func edit(id: String, title: String, content: String, pinned: Bool) async throws
    func delete(id: String) async throws
    func remind(id: String, challengers: [String]) async throws
    func replaceImages(_ files: [String], id: String) async throws
    func replaceLinks(_ links: [String], id: String) async throws
    func removePoll(id: String) async throws
    func confirmRead(id: String) async throws
    func readCounts(id: String) async throws -> NoticeReadCounts
    func readers(id: String, status: String, cursor: String?) async throws -> NoticeReaders
}

public struct NoticeChapter: Codable, Sendable {
    public let chapterId: String
    public let chapterName: String

    public init(
        chapterId: String,
        chapterName: String
    ) {
        self.chapterId = chapterId
        self.chapterName = chapterName
    }

    private enum CodingKeys: CodingKey {
        case chapterId
        case chapterName
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        chapterId = try values.decodeFlexibleString(forKey: .chapterId)
        chapterName = try values.decode(String.self, forKey: .chapterName)
    }

    public func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(chapterId, forKey: .chapterId)
        try values.encode(chapterName, forKey: .chapterName)
    }
}

public struct NoticeSchool: Codable, Sendable {
    public let schoolId: String
    public let schoolName: String

    public init(
        schoolId: String,
        schoolName: String
    ) {
        self.schoolId = schoolId
        self.schoolName = schoolName
    }

    private enum CodingKeys: CodingKey {
        case schoolId
        case schoolName
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        schoolId = try values.decodeFlexibleString(forKey: .schoolId)
        schoolName = try values.decode(String.self, forKey: .schoolName)
    }

    public func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(schoolId, forKey: .schoolId)
        try values.encode(schoolName, forKey: .schoolName)
    }
}

public struct NoticeOrganization: Codable, Sendable {
    public let gisuId: String
    public let generation: String?
    public let chapters: [NoticeChapter]
    public let schools: [NoticeSchool]

    public init(
        gisuId: String,
        generation: String?,
        chapters: [NoticeChapter],
        schools: [NoticeSchool]
    ) {
        self.gisuId = gisuId
        self.generation = generation
        self.chapters = chapters
        self.schools = schools
    }

    private enum CodingKeys: CodingKey {
        case gisuId
        case generation
        case chapters
        case schools
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        gisuId = try values.decodeFlexibleString(forKey: .gisuId)
        generation = try values.decodeFlexibleStringIfPresent(forKey: .generation)
        chapters = try values.decode([NoticeChapter].self, forKey: .chapters)
        schools = try values.decode([NoticeSchool].self, forKey: .schools)
    }

    public func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(gisuId, forKey: .gisuId)
        try values.encodeIfPresent(generation, forKey: .generation)
        try values.encode(chapters, forKey: .chapters)
        try values.encode(schools, forKey: .schools)
    }
}

public enum NoticeRequestFailure: LocalizedError, Equatable, Sendable {
    case accessDenied
    case rejected(String)
    case publicationUnconfirmed
    case pollMissing
    case pollUnconfirmed

    public var errorDescription: String? {
        switch self {
        case .accessDenied: "이 공지를 열거나 변경할 권한이 없습니다."
        case .rejected(let message): message
        case .publicationUnconfirmed: "서버에서 게시 결과를 확인하지 못했습니다. 목록에서 제목을 확인하세요."
        case .pollMissing: "공지 상세에서 투표가 없는 것을 확인했습니다. 투표를 다시 등록할 수 있습니다."
        case .pollUnconfirmed: "투표 등록 결과를 확인하지 못했습니다. 공지 상세에서 다시 확인하세요."
        }
    }
}

/// 서버가 생성 요청 식별자를 제공하지 않아 응답을 잃은 POST는 조회로만 확인한다.
@MainActor
@Observable
public final class NoticePublication {
    public private(set) var noticeID: String?
    public private(set) var needsListCheck = false
    public private(set) var needsPollCheck = false

    public init() {}

    public func publish(_ create: () async throws -> String) async throws -> String {
        if let noticeID { return noticeID }
        guard !needsListCheck else { throw NoticeRequestFailure.publicationUnconfirmed }
        needsListCheck = true
        do {
            let result = try await create()
            noticeID = result
            needsListCheck = false
            return result
        } catch let error as NoticeRequestFailure {
            if case .rejected = error { needsListCheck = false }
            if case .accessDenied = error { needsListCheck = false }
            throw error
        } catch {
            throw NoticeRequestFailure.publicationUnconfirmed
        }
    }

    public enum PollReceipt { case matching, absent, different }

    public func publishPoll(
        create: () async throws -> Void,
        check: () async throws -> PollReceipt
    ) async throws {
        if !needsPollCheck {
            needsPollCheck = true
            do {
                try await create()
                return
            } catch let error as NoticeRequestFailure {
                if case .rejected = error { needsPollCheck = false }
                if case .accessDenied = error { needsPollCheck = false }
                throw error
            } catch {
                try Task.checkCancellation()
            }
        }
        switch try await check() {
        case .matching: return
        case .absent:
            needsPollCheck = false
            throw NoticeRequestFailure.pollMissing
        case .different: throw NoticeRequestFailure.pollUnconfirmed
        }
    }
}
