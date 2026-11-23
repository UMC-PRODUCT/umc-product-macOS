//
//  ThreadManagementContractTests.swift
//  CommunityDataTests
//
//  Created by euijjang97 on 11/23/26.
//

import CommunityDomain
import Foundation
import Testing
@testable import CommunityData

@Suite("스레드 관리 서버 계약")
struct ThreadManagementContractTests {
    @Test func onlyConfirmedDeletionEndsTheThreadAsDeleted() {
        let deleted = Data(#"{"success":false,"code":"COMMUNITY-0037"}"#.utf8)
        let wrongCode = Data(#"{"success":false,"code":"COMMUNITY-0033"}"#.utf8)
        let classify = LiveCommunityThreadRepository.detailError(status:data:)
        #expect(classify(410, deleted) as? ThreadDetailError == .deleted)
        #expect(classify(404, wrongCode) as? ThreadDetailError == .accessDenied)
        #expect(classify(403, nil) as? ThreadDetailError == .accessDenied)
        #expect(!(classify(410, wrongCode) is ThreadDetailError))
        #expect(!(classify(503, deleted) is ThreadDetailError))
    }

    @Test func shareLinkMustComeFromDetailAndIdentifyTheSameThread() throws {
        let detail: [String: Any] = ["threadId": 42, "title": "합성", "icon": "T",
            "isPinned": false, "isMuted": false, "isJoined": true, "unreadCount": "0"]
        let canonical = "https://threads.example.org/community/threads/42"
        for link in [canonical, "umc://thread/42", canonical + "?token=secret",
                     "https://threads.example.org/community/threads/43", "", nil] {
            var fields = detail
            fields["shareUrl"] = link
            let input = try JSONSerialization.data(withJSONObject: fields)
            let model = try JSONDecoder().decode(ThreadResponse.self, from: input).model
            #expect(model.shareURL?.absoluteString == (link == canonical ? canonical : nil))
        }
    }

    @Test("참여자와 초대 후보에서 문자열·숫자 식별자와 nullable 필드 지원")
    func memberPage() throws {
        let input = Data("""
            {"items":[{"memberId":101,"name":"테스트 운영자","role":"OWNER","state":"ACTIVE",
            "generation":"10","part":"PLAN"},{"memberId":"202","name":"테스트 후보","part":null,
            "generation":null}],"total":2,"nextOffset":null}
            """.utf8)
        let response = try JSONDecoder().decode(ThreadManagementPageResponse.self, from: input)
        let output = try JSONEncoder().encode(response)
        let page = try JSONDecoder().decode(ThreadManagementPageResponse.self, from: output).model
        #expect(page.total == "2")
        #expect(page.nextOffset == nil)
        #expect(page.items.map(\.memberId) == ["101", "202"])
        #expect(page.items.map(\.generation) == ["10", nil])
        #expect(page.items.map(\.role) == [.owner, nil])
    }

    @Test("공개 프로필은 서버가 공개한 링크와 활동 기록만 사용")
    func publicProfile() throws {
        let input = Data("""
            {"name":"테스트 회원","nickname":null,"schoolName":"테스트 대학교","email":null,
            "profile":{"github":"https://example.test/public","blog":null},
            "challengerRecords":[{"gisu":10,"part":"DESIGN","points":[]}]}
            """.utf8)
        let profile = try JSONDecoder().decode(ThreadManagementProfileResponse.self,
                                               from: input).model
        #expect(profile.profile?.github == "https://example.test/public")
        #expect(profile.profile?.blog == nil)
        #expect(profile.challengerRecords.first?.gisu == "10")
        #expect(profile.nickname == nil)
    }

    @Test("비참여자 상세에서 역할과 멤버십이 비어 있을 수 있음")
    func nonmemberDetail() throws {
        let input = Data("""
            {"title":"공개 스레드","icon":"💬","category":"FREE","description":null,
            "myRole":null,"membershipState":null,"memberCount":"4","maxMembers":100}
            """.utf8)
        let detail = try JSONDecoder().decode(ThreadManagementDetailResponse.self, from: input)
            .model
        #expect(detail.myRole == nil)
        #expect(detail.membershipState == nil)
        #expect(detail.maxMembers == "100")
    }
}
