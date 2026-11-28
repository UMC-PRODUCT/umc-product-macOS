//
//  SupportFlowTests.swift
//  UMCDeskTests
//
//  Created by euijjang97 on 11/23/26.
//

import Foundation
import Testing

@testable import UMCDesk

struct SupportFlowTests {
    @Test func searchIncludesAnswersAndIgnoresOuterWhitespace() {
        let guide = SupportArticle(id: "guide", question: "앱 언어", answer: "Open Settings")
        #expect(guide.matches("  언어"))
        #expect(guide.matches(" settings "))
        #expect(guide.matches(" "))
        #expect(!guide.matches("네트워크"))
    }

    #if DEBUG
    @MainActor @Test func contentColumnsAndFooterUseActualAvailableSize() {
        for scale in [CGFloat(1), 1.5, 2] {
            for (left, right, ratio) in [
                (600.0, 300.0, 898.0 / 1258), (600, 300, 902.0 / 1258),
                (680, 240, 960.0 / 1258), (252, 520, 330.0 / 1258),
            ] {
                let layout = SupportPanelLayout(
                    scale: scale, firstMinimum: left, secondMinimum: right, fraction: ratio)
                let threshold = (left + right) * scale + 24
                #expect(layout.widths(for: threshold - 1) == nil)
                for width in [threshold, threshold + 1, threshold + 360] {
                    let columns = layout.widths(for: width)
                    #expect((columns?.0 ?? 0) >= left * scale)
                    #expect((columns?.1 ?? 0) >= right * scale)
                    #expect(abs((columns?.0 ?? 0) + (columns?.1 ?? 0) + 24 - width) < 0.00001)
                }
            }
            for delta in [-1.0, 0, 1] {
                #expect(
                    SupportPinnedFooter.fits(
                        height: 160 * scale + 72 + delta, footer: 60, scale: scale) == (delta >= 0)
                )
                let dialog = min(SupportLayoutMetrics.teamWidth, 62 + 600 * scale + delta)
                #expect(
                    (dialog - 2 * SupportLayoutMetrics.teamInset
                        >= SupportLayoutMetrics.teamGridMinimum(scale))
                        == (scale == 1 && delta >= 0))
                #expect(
                    min(
                        SupportLayoutMetrics.toolWidth, 422 + delta - 2 * SupportLayoutMetrics.edge
                    ) == min(390, 390 + delta))
                #expect(
                    (900 * scale + delta >= SupportLayoutMetrics.fullTable(scale)) == (delta >= 0))
                #expect(
                    (640 * scale + delta >= SupportLayoutMetrics.mediumTable(scale))
                        == (delta >= 0))
            }
        }
        for (width, inset) in [
            (911.0, 16.0), (912, 16), (913, 16.125), (976, 24), (1103, 39.875), (1104, 40),
            (1105, 40), (1376, 40),
        ] {
            #expect(abs(SupportContentInsets.horizontal(for: width) - inset) < 0.00001)
        }
    }

    @MainActor @Test func rejectedAndUncertainWritesNeverRepeatOnRead() async {
        let transport = SupportPreviewTransport()
        var applied = 0
        let uncertain = UUID()
        transport.nextWrite = .uncertain
        let result = await transport.send(id: uncertain) { _ in
            applied += 1
            return true
        }
        #expect(result == .uncertain)
        await transport.reload()
        #expect(
            await transport.send(id: uncertain) { _ in
                applied += 1
                return true
            } == .uncertain)
        let rejected = UUID()
        transport.nextWrite = .rejected
        #expect(
            await transport.send(id: rejected) { _ in
                applied += 1
                return true
            } == .failed)
        #expect(applied == 0)
        #expect(
            await transport.send(id: rejected) { _ in
                applied += 1
                return true
            } == .success)
        #expect(
            await transport.send(id: rejected) { _ in
                applied += 1
                return true
            } == .success)
        #expect(applied == 1)
    }

    @MainActor @Test func concurrentSendAndPermissionChangeAreBoundToOriginalIntent() async {
        let transport = SupportPreviewTransport()
        let id = UUID()
        var writes = 0
        let first = Task { @MainActor in
            await transport.send(id: id, requiresOperator: true) { _ in
                writes += 1
                return true
            }
        }
        while transport.receipts[id] == nil { await Task.yield() }
        #expect(
            await transport.send(id: id, requiresOperator: true) { _ in
                writes += 1
                return true
            } == .sending)
        transport.access = .denied
        transport.access = .granted
        #expect(await first.value == .failed)
        #expect(writes == 0)
    }

    @MainActor @Test func partialSuccessPreservesReceiptAndRetainsLastRead() async {
        let transport = SupportPreviewTransport()
        var attachmentIncluded: Bool?
        let id = UUID()
        transport.nextWrite = .attachmentFailed
        #expect(
            await transport.send(id: id, hasAttachment: true) { include in
                attachmentIncluded = include
                return true
            } == .attachmentFailed)
        #expect(attachmentIncluded == false)
        transport.nextReadFails = true
        await transport.reload()
        #expect(transport.read == .failed && transport.hasSnapshot)
        await transport.reload()
        #expect(transport.read == .ready && transport.receipts[id] == .attachmentFailed)
        transport.simulateFailedRead()
        #expect(!transport.hasSnapshot)
        await transport.reload()
        #expect(transport.hasSnapshot)
    }

    @MainActor @Test func sharedWindowsVerifyOneOperationWithoutReplayingTheWrite() async throws {
        for action in ["답변 보내기", "FAQ 발행", "FAQ 보관"] {
            let shared = SupportPreviewTransport()
            let key = SupportPreviewTransport.Key(
                scope: "record", action: action, isOperator: true)
            let first = SupportCommand()
            let other = SupportCommand()
            var writes = 0
            shared.nextWrite = .lostAfterApply
            first.run(action, scope: "record", transport: shared, isOperator: true) { _ in
                writes += 1
                return true
            }
            other.run(action, scope: "record", transport: shared, isOperator: true) { _ in
                writes += 1
                return true
            }
            try await Task.sleep(for: .milliseconds(200))
            #expect(shared.requests.count == 1 && shared.receipts.count == 1 && writes == 1)
            let originalID = shared.requests[key]
            #expect(shared.state(key) == .uncertain)
            shared.nextReadFails = true
            await shared.reload(verifying: key)
            #expect(shared.blocked(key))
            let reopened = SupportCommand()
            reopened.run(action, scope: "record", transport: shared, isOperator: true) { _ in
                writes += 1
                return true
            }
            await shared.reload(verifying: key)
            #expect(
                shared.state(key) == .success && writes == 1 && originalID == shared.requests[key])
            let separateSession = SupportPreviewTransport()
            #expect(separateSession.state(key) == nil)
        }
    }

    @MainActor @Test func verifiedAbsencePermitsOnlyAnExplicitRetryWithOriginalID() async throws {
        let shared = SupportPreviewTransport()
        let key = SupportPreviewTransport.Key(scope: "record", action: "답변", isOperator: false)
        var writes = 0
        let command = SupportCommand()
        shared.nextWrite = .lostBeforeApply
        command.run(key.action, scope: key.scope, transport: shared, isOperator: false) { _ in
            writes += 1
            return true
        }
        try await Task.sleep(for: .milliseconds(200))
        let original = shared.requests[key]
        await shared.reload(verifying: key)
        #expect(shared.state(key) == .failed && writes == 0)
        SupportCommand().run(key.action, scope: key.scope, transport: shared, isOperator: false) {
            _ in
            writes += 1
            return true
        }
        try await Task.sleep(for: .milliseconds(200))
        #expect(shared.requests[key] == original && shared.receipts.count == 1 && writes == 1)
        let unverified = SupportPreviewTransport.Key(
            scope: "other", action: key.action, isOperator: false)
        shared.nextWrite = .uncertain
        _ = await shared.send(id: UUID(), key: unverified) { _ in
            writes += 1
            return true
        }
        await shared.reload(verifying: unverified)
        #expect(shared.blocked(unverified) && !shared.blocked(key) && writes == 1)
    }

    @MainActor @Test func closedTicketRejectsStaleOperatorActionsAndOwnerCanReopen() async {
        let fixture = SupportFixture()
        let id = fixture.tickets[0].id
        let key = SupportPreviewTransport.Key(
            scope: id.uuidString, action: "라벨 적용", isOperator: true)
        let pending = Task { @MainActor in
            await fixture.transport.send(id: UUID(), key: key, requiresOperator: true) { _ in
                fixture.modifyOpenTicket(id) {
                    $0.applyLabels(original: $0.labels, selected: ["기능 요청"])
                }
            }
        }
        while fixture.transport.state(key) == nil { await Task.yield() }
        fixture.tickets[0].changeStatus(.closed, by: .agent)
        let closed = fixture.tickets[0]
        #expect(await pending.value == .failed)
        #expect(
            !fixture.modifyOpenTicket(id) {
                $0.assignee = "이지원"
                $0.linkedQuestion = "login"
            })
        fixture.tickets[0].changeStatus(.active, by: .agent)
        #expect(
            fixture.tickets[0].status == .closed
                && fixture.tickets[0].history.count == closed.history.count
                && fixture.tickets[0].labels == closed.labels)
        let reopened = fixture.tickets[0].reply("다시 문의할게요.", from: .requester)
        #expect(reopened)
        #expect(fixture.tickets[0].id == id && fixture.tickets[0].status == .active)
    }

    @MainActor @Test func leavingEditedWorkspaceNeedsOneDecision() {
        let gate = SupportExitGate()
        var destination = "고객센터"
        gate.hasChanges = true
        gate.request { destination = "홈" }
        #expect(gate.needsConfirmation && destination == "고객센터")
        gate.stay()
        #expect(gate.hasChanges && destination == "고객센터")
        var departures = 0
        gate.request {
            destination = "매칭"
            departures += 1
        }
        gate.discard()
        gate.discard()
        #expect(!gate.hasChanges && destination == "매칭" && departures == 1)
        gate.request { destination = "홈" }
        #expect(destination == "홈")
    }

    @Test func menuPlacementFlipsOrLimitsItsScrollingArea() {
        for (height, prefix, field, menu) in [
            (600.0, 60.0, 44.0, 280.0), (600, 440, 44, 280), (320, 170, 48, 450),
        ] {
            let result = SupportFieldMenuPlacement.position(
                height: height, prefix: prefix, field: field, menu: menu)
            #expect(result.menuY >= 0 && result.menuY + result.menuHeight <= height)
            #expect(
                result.menuY >= result.fieldY + field
                    || result.menuY + result.menuHeight <= result.fieldY)
            #expect(
                abs(result.menuHeight - min(menu, max(prefix - 6, height - prefix - field - 6)))
                    < 0.001)
        }
    }

    @MainActor @Test func discardedDraftKeepsItsReceiptUntilTheSessionVerifiesCreation() async {
        let fixture = SupportFixture(emptyInquiries: true)
        let key = SupportPreviewTransport.createKey
        let original = UUID()
        let transport = fixture.transport
        var creates = 0
        func submit(_ request: UUID) async -> SupportPreviewTransport.Receipt {
            await transport.send(id: request, key: key) { _ in
                creates += 1
                guard let ticket = fixture.create(subject: "제목", content: "본문", team: .platform)
                else { return false }
                transport.rememberTicket(ticket, request: request)
                return true
            }
        }
        transport.nextWrite = .lostAfterApply
        #expect(await submit(original) == .uncertain)
        let gate = SupportExitGate()
        gate.hasChanges = true
        gate.request {}
        gate.discard()
        let newDraft = UUID()
        #expect(await submit(newDraft) == .uncertain)
        #expect(transport.requests[key] == original && creates == 1 && fixture.tickets.count == 1)
        transport.nextReadFails = true
        await transport.reload(verifying: key)
        #expect(transport.blocked(key) && transport.requests[key] == original)
        await transport.reload(verifying: key)
        #expect(transport.state(key) == .success && fixture.tickets.count == 1 && creates == 1)
        #expect(transport.submittedTickets[original] == fixture.tickets[0].id)
        #expect(await submit(newDraft) == .success)
        #expect(creates == 2 && fixture.tickets.count == 2 && transport.requests[key] == newDraft)
        #expect(SupportFixture().transport.requests[key] == nil)
    }

    @Test func replyAcknowledgementClearsOnlyTheSubmittedEditorRevision() {
        let id = UUID()
        let sent = SupportPreviewTransport.ReplyInput(text: "원문", attachment: true)
        var author = SupportPreviewTransport.ReplyDraft(input: sent, request: id)
        var other = SupportPreviewTransport.ReplyDraft(input: sent)
        let clearedOther = other.acknowledge(id, receipt: .success)
        #expect(!clearedOther)
        #expect(other.input == sent)
        let clearedUnrelated = author.acknowledge(UUID(), receipt: .success)
        #expect(!clearedUnrelated)
        let clearedSubmitted = author.acknowledge(id, receipt: .success)
        #expect(clearedSubmitted)
        #expect(author.input == .init())

        for changeAttachment in [true, false] {
            var editor = SupportPreviewTransport.ReplyDraft(input: sent, request: id)
            if changeAttachment { editor.input.attachment.toggle() } else { editor.input.text = "다음 답변" }
            let revised = editor.input
            let clearedRevised = editor.acknowledge(id, receipt: .success)
            #expect(!clearedRevised)
            #expect(editor.input == revised)
            editor.input = sent
            let clearedReverted = editor.acknowledge(id, receipt: .success)
            #expect(!clearedReverted)
            #expect(editor.input == sent)
        }
    }

    @MainActor @Test func obsoleteRetryCannotChangeAnotherRequestsPayload() async throws {
        let transport = SupportPreviewTransport()
        let key = SupportPreviewTransport.Key(scope: "ticket", action: "답변 보내기", isOperator: true)
        let a = SupportCommand()
        let b = SupportCommand()
        var sent: [String] = []
        func send(_ command: SupportCommand, _ body: String) {
            command.run(
                key.action, scope: key.scope, transport: transport, isOperator: true,
                payload: [body]
            ) { _ in
                sent.append(body)
                return true
            }
        }
        transport.nextWrite = .rejected
        send(a, "첫 답변")
        try await Task.sleep(for: .milliseconds(200))
        let first = transport.requests[key]
        let obsolete = try #require(a.actions.first?.retry)
        send(b, "첫 답변")
        try await Task.sleep(for: .milliseconds(200))
        #expect(transport.requests[key] == first && sent == ["첫 답변"])
        transport.nextWrite = .rejected
        send(b, "후속 답변")
        try await Task.sleep(for: .milliseconds(200))
        let later = transport.requests[key]
        #expect(first != later)
        obsolete()
        try await Task.sleep(for: .milliseconds(200))
        #expect(
            transport.state(key) == .failed && transport.requests[key] == later && sent == ["첫 답변"]
        )
        b.actions.first?.retry?()
        try await Task.sleep(for: .milliseconds(200))
        #expect(sent == ["첫 답변", "후속 답변"] && transport.requests[key] == later)
    }

    @Test func ordinaryPreviewQueueAndSuggestedDraftUseSharedRecords() throws {
        let preview = SupportFixture()
        var selectedQueue = SupportQueue.all
        #expect(preview.tickets.filter(selectedQueue.includes).count == 5)
        #expect(preview.tickets.filter(SupportQueue.unassigned.includes).count == 3)
        let first = try #require(preview.tickets.first)
        #expect(first.status == .received && first.assignee == "미배정" && first.replies.isEmpty)
        selectedQueue = .mine
        #expect(preview.tickets.filter(selectedQueue.includes).count == 2)
        selectedQueue = .unclassified
        #expect(preview.tickets.filter(selectedQueue.includes).count == 3)
        let recommendation = try #require(preview.suggestedDraft)
        #expect(recommendation.article.question == "알림이 오지 않아요")
        #expect(recommendation.isValid && recommendation.status == "초안")
        #expect(preview.drafts.contains { $0.archived })
        #expect(preview.drafts.contains { $0.status == "수정 중" })
        preview.apply(.publish, draft: recommendation)
        #expect(preview.suggestedDraft == nil)
        #expect(preview.publishedArticle(id: recommendation.id) == recommendation.article)
    }

    @Test func archivedArticleDisappearsFromOpenDetailAndNewReferences() throws {
        let preview = SupportFixture()
        let editor = try #require(preview.drafts.first)
        let detailID = editor.id
        let opened = try #require(preview.publishedArticle(id: detailID))
        let previous = try #require(
            preview.create(subject: "기존", content: "본문", team: .platform, reference: opened))
        preview.apply(.archive, draft: editor)
        #expect(preview.publishedArticle(id: detailID) == nil)
        let next = try #require(
            preview.create(subject: "이후", content: "본문", team: .platform, reference: opened))
        #expect(preview.tickets.first { $0.id == next }?.reference == nil)
        #expect(preview.tickets.first { $0.id == previous }?.reference == opened)
    }

    @Test func audienceWithdrawalKeepsOperatorAccessAndPreventsNewRequesterReferences() throws {
        let fixture = SupportFixture()
        var draft = try #require(fixture.drafts.first)
        let opened = try #require(fixture.publishedArticle(id: draft.id))
        draft.article.audience = "UMC 운영진"
        fixture.apply(.publish, draft: draft)
        #expect(fixture.operatorPublishedArticles.contains(draft.article))
        #expect(fixture.publishedArticle(id: opened.id) == nil)
        #expect(
            fixture.publishedArticles.contains {
                $0.id != opened.id && $0.category == opened.category
            })
        let id = try #require(
            fixture.create(
                subject: "나의 입력", content: "작성 중 본문", team: .platform, reference: opened,
                attachmentName: "예시.png"))
        let ticket = try #require(fixture.tickets.first { $0.id == id })
        #expect(
            ticket.reference == nil && ticket.content == "작성 중 본문"
                && ticket.attachmentName == "예시.png")
        draft.article.audience = "UMC 서비스 사용자"
        fixture.apply(.publish, draft: draft)
        #expect(fixture.publishedArticle(id: opened.id) == draft.article)
    }

    @Test func staleEditorCannotRestoreArchivedPublication() throws {
        let fixture = SupportFixture()
        var older = try #require(fixture.drafts.first)
        fixture.apply(.archive, draft: older)
        older.article.answer = "두 번째 창의 초안"
        let saved = fixture.apply(.save, draft: older)
        #expect(saved.archived && saved.published == nil)
        #expect(!fixture.publishedArticles.contains { $0.id == older.id })
        #expect(saved.article.answer == older.article.answer)
    }

    @Test func concurrentLabelEditsAppendHistoryOncePerMutation() throws {
        var ticket = try #require(SupportFixture().tickets.first)
        let initial = ticket.labels
        let originalCount = ticket.history.count
        ticket.applyLabels(original: initial, selected: initial)
        #expect(ticket.history.count == originalCount)
        ticket.applyLabels(original: initial, selected: initial + ["기능 요청"])
        ticket.applyLabels(original: initial, selected: initial.filter { $0 != "정보 확인" })
        #expect(ticket.labels.contains("기능 요청"))
        #expect(!ticket.labels.contains("정보 확인"))
        #expect(ticket.history.count == originalCount + 2)
        #expect(Set(ticket.history.map(\.id)).count == ticket.history.count)
    }

    @Test func localInquiryLifecycle() throws {
        let fixture = SupportFixture()
        let otherWindow = SupportFixture()
        let initialCount = fixture.tickets.count
        #expect(fixture.create(subject: "  ", content: "예시", team: .operations) == nil)
        let id = try #require(fixture.create(subject: " 예시 ", content: " 문의 ", team: .operations))
        let index = try #require(fixture.tickets.firstIndex { $0.id == id })
        #expect(fixture.tickets.count == initialCount + 1)
        #expect(otherWindow.tickets.count == initialCount)
        #expect(fixture.tickets[index].team == .operations)
        #expect(fixture.tickets[index].subject == "예시")
        fixture.tickets[index].assignee = "예시 담당자"
        #expect(fixture.tickets[index].status == .received)
        fixture.tickets[index].reply("확인 중", from: .agent)
        #expect(fixture.tickets[index].status == .active)
        fixture.tickets[index].status = .closed
        fixture.tickets[index].reply("종료 뒤 운영자 입력", from: .agent)
        #expect(fixture.tickets[index].replies.map(\.text) == ["확인 중"])
    }

    @Test func emptyPreviewAcceptsFirstInquiryWithoutOtherUsersData() throws {
        let fixture = SupportFixture(emptyInquiries: true)
        #expect(fixture.tickets.isEmpty)
        #expect(!fixture.publishedArticles.isEmpty)
        let id = try #require(fixture.create(subject: "첫 문의", content: "내용", team: .product))
        #expect(fixture.myTickets.map(\.id) == [id])
        #expect(fixture.myTickets[0].status == .received)
    }

    @Test func requesterMessageReopensOriginalTicketOnlyAfterSending() throws {
        let fixture = SupportFixture()
        let closed = try #require(fixture.myTickets.first { $0.status == .closed })
        let index = try #require(fixture.tickets.firstIndex { $0.id == closed.id })
        let count = fixture.tickets.count
        for blank in ["", "  \n "] {
            fixture.tickets[index].reply(blank, from: .requester)
            #expect(fixture.tickets[index].status == .closed)
            #expect(fixture.tickets[index].replies.count == closed.replies.count)
        }
        fixture.tickets[index].reply(" 다시 확인해 주세요 ", from: .requester)
        let reopened = try #require(fixture.myTickets.first { $0.id == closed.id })
        #expect(fixture.tickets.count == count)
        #expect(reopened.status == .active)
        #expect(reopened.history.last?.actor == "문의자")
        #expect(reopened.replies.dropLast().map(\.id) == closed.replies.map(\.id))
        #expect(reopened.replies.last?.author == .requester)
        #expect(reopened.replies.last?.text == "다시 확인해 주세요")
    }

    @Test func myInquiriesExcludeOtherUsersAndKeepReplyAuthors() throws {
        let fixture = SupportFixture()
        let other = try #require(fixture.tickets.first { !$0.belongsToCurrentUser })
        #expect(!fixture.myTickets.contains { $0.id == other.id })
        let id = try #require(fixture.create(subject: "질문", content: "예시 본문", team: .product))
        let index = try #require(fixture.tickets.firstIndex { $0.id == id })
        fixture.tickets[index].reply("추가 설명", from: .requester)
        #expect(fixture.tickets[index].status == .received)
        fixture.tickets[index].reply("확인했어요", from: .agent)
        let mine = try #require(fixture.myTickets.first { $0.id == id })
        #expect(mine.replies.map(\.author) == [.requester, .agent])
        #expect(mine.status == .active)
        var inaccessible = other
        inaccessible.reply("다른 사용자의 문의에 입력", from: .requester)
        #expect(inaccessible.replies.isEmpty)
    }

    @Test func draftEditsAreVisibleOnlyAfterPublication() throws {
        let fixture = SupportFixture()
        let original = try #require(fixture.publishedArticles.first)
        fixture.drafts[0].article.answer = "새 예시 답변"
        #expect(fixture.drafts[0].status == "수정 중")
        #expect(fixture.publishedArticles.first == original)
        fixture.drafts[0].publish()
        #expect(fixture.publishedArticles.first?.answer == "새 예시 답변")
        fixture.drafts[0].archive()
        #expect(!fixture.publishedArticles.contains { $0.id == original.id })
    }
    #endif
}
