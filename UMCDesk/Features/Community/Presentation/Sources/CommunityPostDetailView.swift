//
//  CommunityPostDetailView.swift
//  CommunityPresentation
//
//  Created by euijjang97 on 11/23/26.
//

import CommunityDomain
import CoreDesignSystem
import SwiftUI

struct CommunityPostDetailView: View {
    let id: String
    let accountID: String
    let repository: any CommunityPostRepository
    let changed: (Bool) -> Void
    @State private var post: CommunityPost?
    @State private var comments: [CommunityPostComment] = []
    @State private var input = ""
    @State private var reply: CommunityPostComment?
    @State private var failure: String?
    @State private var awaitingConfirmation = false
    @State private var feedback: String?
    @State private var editing = false
    @State private var removal: Removal?
    @State private var busy = false
    @State private var operation: Task<Void, Never>?
    @State private var reload = 0
    @State private var revision = 0
    @FocusState private var commenting: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let post {
                header(post).padding([.horizontal, .top], UMCSpacing.value24)
            }
            detailScroll
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .disabled(busy)
        .overlay { if busy { ProgressView("처리 중") } }
        .task(id: reload) { await fetch() }
        .onDisappear { operation?.cancel() }
        .sheet(isPresented: $editing) {
            if let post {
                CommunityPostEditor(existing: post, repository: repository) { updated in
                    self.post = updated
                    editing = false
                    changed(false)
                    reload += 1
                }
            }
        }
        .confirmationDialog(
            "삭제할까요?",
            isPresented: Binding(
                get: { removal != nil },
                set: { if !$0 { removal = nil } }), presenting: removal
        ) { target in
            Button("삭제", role: .destructive) {
                switch target {
                case .post: act(.delete)
                case .comment(let id): act(.deleteComment(id))
                }
            }
        } message: { _ in
            Text("삭제한 내용은 복구할 수 없어요.")
        }
    }

    private var detailScroll: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: UMCSpacing.value16) {
                if let failure {
                    Text(failure)
                    Button("상세 다시 불러오기") { reload += 1 }
                }
                if let post {
                    Text(post.title).umcTypography(.title1Bold).textSelection(.enabled)
                    HStack {
                        if let author = post.author { Text(author) }
                        if let date = post.date { Text(CommunityPostDate.display(date)) }
                    }.foregroundStyle(.secondary)
                    Text(post.content).textSelection(.enabled)
                    if let meeting = post.meeting { meetingInfo(meeting) }
                    HStack {
                        Button(
                            "좋아요 \(post.likeCount)",
                            systemImage: post.liked ? "heart.fill" : "heart"
                        ) { act(.like) }
                        Button(
                            "스크랩 \(post.scrapCount ?? "0")",
                            systemImage: post.scrapped ? "bookmark.fill" : "bookmark"
                        ) { act(.scrap) }
                    }
                    Divider()
                    Text("댓글 \(post.commentCount)").font(.headline)
                    ForEach(comments) { comment in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(comment.author ?? "댓글 작성자").fontWeight(.medium)
                                Spacer()
                                Menu("댓글 동작", systemImage: "ellipsis") {
                                    Button("답글") {
                                        reply = comment
                                        commenting = true
                                    }.disabled(awaitingConfirmation)
                                    Button("좋아요 전환") { act(.likeComment(comment.id)) }
                                    if comment.isAuthor {
                                        Button("댓글 삭제", role: .destructive) {
                                            removal = .comment(comment.id)
                                        }
                                    }
                                }.labelStyle(.iconOnly).fixedSize()
                            }
                            Text(comment.content).textSelection(.enabled)
                        }.padding(12).background(
                            UMCColor.Custom.backgroundSurfaceGreyWeaker,
                            in: .rect(cornerRadius: 10))
                    }
                    if let reply {
                        HStack {
                            Text("\(reply.author ?? "댓글")에 답글").font(.caption)
                            Button("답글 취소") { self.reply = nil }.disabled(awaitingConfirmation)
                        }
                    }
                    HStack {
                        TextField("댓글을 입력하세요", text: $input, axis: .vertical)
                            .lineLimit(1...5).focused($commenting).disabled(awaitingConfirmation)
                        Button(awaitingConfirmation ? "등록 결과 확인" : "등록") {
                            act(.comment(input, parentID: reply?.id))
                        }
                            .disabled(
                                input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    if awaitingConfirmation {
                        Button("댓글 작성 취소") {
                            awaitingConfirmation = false
                            input = ""
                            reply = nil
                            feedback = nil
                        }
                    }
                    if let feedback { Text(feedback).font(.callout) }
                } else if failure == nil {
                    ProgressView("게시글 불러오는 중")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(UMCSpacing.value24)
        }
    }

    private func header(_ post: CommunityPost) -> some View {
        HStack {
            Text(
                CommunityPostCategory(rawValue: post.category)?.label ?? post.category
            )
            .foregroundStyle(UMCColor.Semantic.textBrandDefault)
            Spacer()
            if post.authorMemberID == accountID {
                Menu("게시글 관리", systemImage: "ellipsis.circle") {
                    Button("수정") { editing = true }
                    Button("삭제", role: .destructive) { removal = .post }
                }.fixedSize()
            }
        }
    }

    private func meetingInfo(_ meeting: CommunityPostMeeting) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(CommunityPostDate.display(meeting.meetAt), systemImage: "calendar")
            Label(meeting.location, systemImage: "mappin")
            Label("최대 \(meeting.maxParticipants)명", systemImage: "person.2")
            if let url = URL(string: meeting.openChatUrl), ["https", "http"].contains(url.scheme) {
                Link("오픈 채팅 열기", destination: url)
            }
        }
    }

    @MainActor private func fetch() async {
        revision += 1
        let expected = revision
        do {
            async let detail = repository.post(id: id)
            async let replies = repository.comments(id: id)
            let (current, values) = try await (detail, replies)
            try Task.checkCancellation()
            guard revision == expected else { return }
            post = current
            comments = values
            if !awaitingConfirmation, let reply, !values.contains(where: { $0.id == reply.id }) { self.reply = nil }
            failure = nil
        } catch {
            if !Task.isCancelled && revision == expected {
                post = nil
                comments = []
                failure = error.localizedDescription
            }
        }
    }

    private func act(_ action: CommunityPostAction) {
        guard !busy else { return }
        busy = true
        revision += 1
        feedback = nil
        operation = Task { @MainActor in
            defer { busy = false }
            do {
                let result = try await repository.perform(action, id: id)
                try Task.checkCancellation()
                switch action {
                case .delete:
                    changed(true)
                    return
                case .comment:
                    awaitingConfirmation = false
                    input = ""
                    reply = nil
                case .likeComment: feedback = result == true ? "댓글에 좋아요를 눌렀어요." : "댓글 좋아요를 취소했어요."
                default: break
                }
                changed(false)
                await fetch()
            } catch {
                if !Task.isCancelled {
                    if error as? CommunityPostWriteFailure == .unconfirmed {
                        awaitingConfirmation = true
                        feedback = error.localizedDescription
                        return
                    }
                    // An interrupted toggle may already have committed. Recover by reading.
                    post = nil
                    comments = []
                    failure = error.localizedDescription
                }
            }
        }
    }

    private enum Removal {
        case post
        case comment(String)
    }
}

enum CommunityPostDate {
    static func parse(_ raw: String) -> Date? {
        (try? Date(raw, strategy: .iso8601))
            ?? (try? Date(raw, strategy: Date.ISO8601FormatStyle(includingFractionalSeconds: true)))
    }

    static func display(_ raw: String) -> String {
        parse(raw)?.formatted(date: .abbreviated, time: .shortened) ?? raw
    }
}
