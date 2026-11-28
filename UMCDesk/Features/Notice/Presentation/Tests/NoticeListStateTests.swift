//  NoticeListStateTests.swift
//  NoticePresentationTests
//
//  Created by euijjang97 on 11/27/26.

import Foundation
import NoticeDomain
import Testing
import UMCFoundation

@testable import NoticePresentation

@MainActor
struct NoticeListStateTests {
    @Test func rejectedDeletionPreservesContentAndDoesNotReload() async throws {
        let repository = ListRepository()
        await repository.rejectDeletion(.rejected("삭제를 완료하지 못했습니다."))
        let operation = NoticeArticleOperation()
        let access = NoticeAccessState()
        access.entry = try noticeEntry()
        var changes = 0
        var removals = 0
        await operation.delete(
            repository: repository, id: "1", hasContent: { access.entry != nil },
            onAccessLost: { access.revoke() }, onChanged: { changes += 1 },
            onDelete: { removals += 1 })
        #expect(operation.failure?.action == .delete)
        #expect(operation.failure?.isInitialLoad == false)
        #expect(operation.failure?.message == "삭제를 완료하지 못했습니다.")
        #expect(access.entry?.id == "1" && changes == 0 && removals == 0)
        #expect(await repository.deletedIDs == ["1"])
        #expect(await repository.pages.isEmpty)
        #expect(!operation.isBusy)
    }

    @Test func deletionSuccessAndAccessLossKeepExistingCallbacks() async throws {
        let repository = ListRepository()
        let operation = NoticeArticleOperation()
        let access = NoticeAccessState()
        access.entry = try noticeEntry()
        var changes = 0
        var removals = 0
        await operation.delete(
            repository: repository, id: "1", hasContent: { access.entry != nil },
            onAccessLost: { access.revoke() }, onChanged: { changes += 1 },
            onDelete: { removals += 1 })
        #expect(changes == 1 && removals == 1 && operation.failure == nil)
        await repository.rejectDeletion(.accessDenied)
        await operation.delete(
            repository: repository, id: "1", hasContent: { access.entry != nil },
            onAccessLost: { access.revoke() }, onChanged: { changes += 1 },
            onDelete: { removals += 1 })
        #expect(access.entry == nil && changes == 1 && removals == 1)
        #expect(operation.failure == nil && !operation.isBusy)
    }

    @Test func anotherArticleOperationBlocksDuplicateDeletion() async {
        let repository = ListRepository()
        let operation = NoticeArticleOperation()
        await operation.perform(hasContent: { true }, onAccessLost: {}) {
            // The same guard protects delete while any article action is pending.
            await operation.delete(
                repository: repository, id: "1", hasContent: { true },
                onAccessLost: {}, onChanged: {}, onDelete: {})
        }
        #expect(await repository.deletedIDs.isEmpty)
        #expect(!operation.isBusy)
    }

    @Test func newSelectionReturnsToSplitAfterFullReader() {
        var layout = NoticeReadingLayout()
        layout.toggle()
        #expect(layout.isFullReader)
        layout.beginSelection()
        #expect(!layout.isFullReader)
        layout.toggle()
        layout.toggle()
        #expect(!layout.isFullReader)
    }

    @Test func loadedArticleFailureDoesNotClaimTheContentFailedToLoad() {
        let message = "선택한 투표 항목을 확인하세요."
        let initial = NoticeArticleFailure(message: message, hasContent: false)
        let action = NoticeArticleFailure(message: message, hasContent: true)
        #expect(initial.isInitialLoad)
        #expect(!action.isInitialLoad)
        #expect(initial.heading != action.heading)
        #expect(action.message == message)
    }

    @Test func emptyReasonsAreExclusiveAndRespectLoadedPageScope() throws {
        let entry = try noticeEntry()
        func state(_ entries: [NoticeEntry] = [], loading: Bool = false,
                   error: Bool = false, keyword: String = "", pinned: Bool = false,
                   next: Bool = false) -> NoticeEmptyState {
            NoticeEmptyState(entries: entries, loading: loading, hasError: error,
                             keyword: keyword, pinnedOnly: pinned, hasNext: next)
        }
        #expect(state() == .empty)
        #expect(state(keyword: "회의") == .search)
        #expect(state(pinned: true) == .pinned)
        #expect(state([entry], pinned: true, next: true) == .pinnedPage)
        #expect(state([entry], pinned: true) == .pinned)
        #expect(state(loading: true, keyword: "회의", pinned: true) == .none)
        #expect(state(error: true, pinned: true) == .none)
        #expect(state([entry]) == .none)
    }

    @Test func noticePeriodsIncludeBothEndsAndExcludeTomorrow() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(secondsFromGMT: 0))
        let now = try Date.ISO8601FormatStyle().parse("2026-11-30T10:00:00Z")
        let start = try Date.ISO8601FormatStyle().parse("2026-11-24T18:00:00Z")
        func includes(_ period: NoticePeriod, _ day: String) -> Bool {
            period.includes(day + "T00:00:00.123Z", start: start, end: now,
                            now: now, calendar: calendar)
        }
        #expect(includes(.week, "2026-11-24") && !includes(.week, "2026-11-23"))
        #expect(includes(.month, "2026-11-01") && !includes(.month, "2026-10-31"))
        #expect(includes(.day, "2026-11-24") && !includes(.day, "2026-11-25"))
        #expect(includes(.range, "2026-11-24") && includes(.range, "2026-11-30"))
        #expect(!includes(.week, "2026-12-01"))
    }

    @Test func accessibleStateDoesNotInventUnreadOrVoteDetails() throws {
        let entry = try noticeEntry(pinned: true)
        let value = entry.rowAccessibilityValue(selected: true, confirmed: true)
        for label in ["선택됨", "고정", "읽음", "투표"] {
            #expect(value.contains(label))
        }
        #expect(entry.vote == nil)
        #expect(!entry.rowAccessibilityValue(selected: false, confirmed: false).contains("읽음"))
        #expect(!value.contains("마감"))
    }

    @Test func resetAppearsForEachAppliedNoticeFilter() {
        let model = NoticeBoardModel(repository: ListRepository())
        #expect(!model.hasFilters(pinnedOnly: false))
        #expect(model.hasFilters(pinnedOnly: true))
        model.tab = "CENTRAL_MEMBER"
        #expect(model.hasFilters(pinnedOnly: false))
        model.tab = "CHALLENGER"
        model.part = "DESIGN"
        #expect(model.hasFilters(pinnedOnly: false))
        model.part = nil
        model.keyword = "회의"
        #expect(model.hasFilters(pinnedOnly: false))
    }

    @Test func summaryUsesSubmittedKeywordAndHidesInapplicablePart() {
        let model = NoticeBoardModel(repository: ListRepository())
        model.keyword = "제출한 검색어"
        model.part = "DESIGN"
        #expect(model.filterSummary(pinnedOnly: true).contains("제출한 검색어"))
        #expect(model.filterSummary(pinnedOnly: true).contains("디자인"))
        model.tab = "CENTRAL_MEMBER"
        #expect(!model.filterSummary(pinnedOnly: false).contains("디자인"))
    }

    @Test func sameFilterFailurePreservesRowsAndRetriesFailedPage() async throws {
        let repository = ListRepository()
        let model = NoticeBoardModel(repository: repository)
        await model.load()
        #expect(model.entries.map(\.id) == ["1"] && model.nextPage == 1)
        await repository.fail(.connection)
        await model.load(page: 1)
        #expect(model.entries.map(\.id) == ["1"] && model.failedPage == 1)
        await repository.fail(nil)
        await model.load(page: model.failedPage)
        #expect(model.entries.map(\.id) == ["1", "2"])
        #expect(await repository.pages == [0, 1, 1])
        await repository.fail(.connection)
        await model.load()
        #expect(model.entries.count == 2)
        model.keyword = "새 조건"
        await model.load()
        #expect(model.entries.isEmpty && model.nextPage == nil)
    }

    @Test func listAndArticleRevocationHaveDifferentRemovalScopes() async throws {
        let repository = ListRepository()
        let model = NoticeBoardModel(repository: repository)
        await model.load()
        await model.load(page: 1)
        model.readIDs = ["1", "2"]
        model.revokeArticle("1")
        #expect(model.entries.map(\.id) == ["2"] && model.readIDs == ["2"])
        await repository.fail(.denied)
        await model.load()
        #expect(model.entries.isEmpty && model.readIDs.isEmpty && !model.canCompose)
        #expect(model.accessLossRevision == 1 && model.nextPage == nil)
    }
}

private func noticeEntry(id: String = "1", pinned: Bool = false) throws -> NoticeEntry {
    let data = """
        {"id":"\(id)","title":"긴 제목 전체를 접근성 이름으로 제공하는 공지",
        "content":"본문","mustRead":\(pinned),"viewCount":"1",
        "createdAt":"2026-11-27T00:00:00Z","hasVote":true}
        """
    return try JSONDecoder().decode(NoticeEntry.self, from: Data(data.utf8))
}

/// No network, persistent storage or mutation endpoints are used by list regression scenarios.
private actor ListRepository: NoticeRepository {
    enum Failure { case connection, denied }
    var pages: [Int] = []
    private var failure: Failure?
    private var deletionFailure: NoticeRequestFailure?
    var deletedIDs: [String] = []
    func rejectDeletion(_ failure: NoticeRequestFailure) { deletionFailure = failure }
    func fail(_ value: Failure?) { failure = value }
    func activeGisu() async throws -> String { "10" }
    func canCompose(gisu: String) async throws -> Bool { true }
    func notices(gisu: String, tab: String, keyword: String, part: String?, page: Int)
        async throws -> NoticePage {
        pages.append(page)
        if failure == .connection { throw URLError(.notConnectedToInternet) }
        if failure == .denied { throw NoticeRequestFailure.accessDenied }
        let entry = try noticeEntry(id: page == 0 ? "1" : "2")
        let encoded = try JSONEncoder().encode(entry)
        let text = String(decoding: encoded, as: UTF8.self)
        return try JSONDecoder().decode(NoticePage.self, from: Data(
            "{\"content\":[\(text)],\"hasNext\":\(page == 0)}".utf8))
    }
    func openPublicationJournal() async throws -> NoticePublicationJournal { throw unused }
    func currentMemberID() async throws -> String { throw unused }
    func organization(gisu: String) async throws -> NoticeOrganization? { throw unused }
    func detail(id: String) async throws -> NoticeEntry { throw unused }
    func create(_ draft: NoticeDraft, gisu: String) async throws -> String { throw unused }
    func attachLinks(_ links: [String], id: String) async throws { throw unused }
    func uploadImage(file: URL) async throws -> String { throw unused }
    func attachImages(_ files: [String], id: String) async throws { throw unused }
    func addPoll(_ poll: NoticePollDraft, id: String) async throws { throw unused }
    func vote(options: [String], replacing: Bool, id: String) async throws { throw unused }
    func permissions(id: String) async throws -> Set<String> { throw unused }
    func edit(id: String, title: String, content: String, pinned: Bool) async throws { throw unused }
    func delete(id: String) async throws {
        deletedIDs.append(id)
        if let deletionFailure { throw deletionFailure }
    }
    func remind(id: String, challengers: [String]) async throws { throw unused }
    func replaceImages(_ files: [String], id: String) async throws { throw unused }
    func replaceLinks(_ links: [String], id: String) async throws { throw unused }
    func removePoll(id: String) async throws { throw unused }
    func confirmRead(id: String) async throws { throw unused }
    func readCounts(id: String) async throws -> NoticeReadCounts { throw unused }
    func readers(id: String, status: String, cursor: String?) async throws -> NoticeReaders {
        throw unused
    }
    private var unused: Error { NoticeRequestFailure.rejected("Unused test operation") }
}
