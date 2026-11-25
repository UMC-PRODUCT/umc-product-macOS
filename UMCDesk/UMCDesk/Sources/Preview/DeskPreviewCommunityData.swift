//
//  DeskPreviewCommunityData.swift
//  UMCDesk
//
//  Created by euijjang97 on 11/25/26.
//

import Foundation

struct DeskPreviewCommunityData {
    private typealias Row = [String: Any]

    mutating func result(for request: URLRequest) -> Any? {
        guard let url = request.url,
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        else { return nil }
        let path = url.path
        let query = (components.queryItems ?? []).reduce(into: [String: String]()) {
            $0[$1.name] = $1.value
        }
        if request.httpMethod == "POST", path.hasSuffix("/read"),
           path.hasPrefix("/api/v1/notices/"),
           notices.contains(where: { path == "/api/v1/notices/" + ($0["id"] as? String ?? "") + "/read" }) {
            return NSNull()
        }

        let parts = path.split(separator: "/").map(String.init)
        guard parts.starts(with: ["api", "v1"]) else { return nil }
        let route = Array(parts.dropFirst(2))
        if request.httpMethod != "GET" {
            return mutate(route, method: request.httpMethod ?? "", body: DataPreviewFixtures.body(request))
        }
        switch route.first {
        case "notices": return noticeResult(Array(route.dropFirst()), query)
        case "posts": return postResult(Array(route.dropFirst()), query)
        case "community" where route.dropFirst().first == "threads":
            return threadResult(Array(route.dropFirst(2)), query)
        case "authorization" where route == ["authorization", "resource-permission"]
                && query["resourceType"] == "NOTICE":
            return ["permissions": ["READ", "CHECK", "EDIT", "DELETE"].map {
                ["permissionType": $0, "hasPermission": (["READ", "CHECK"].contains($0) || notices.first { $0["id"] as? String == query["resourceId"] }?["authorMemberId"] as? String == "101")]
            }]
        case "member" where route == ["member", "blocks"]:
            return ["members": blocked.map { ["memberId": $0, "isBlocked": true] as Row }]
        default: return nil
        }
    }

    private var nextID = 1000
    private var blocked: Set<String> = []
    private var comments: [String: [Row]] = ["31": [
        ["commentId": "71", "challengerName": "김유엠", "challengerNickname": "유엠",
         "content": "저희는 리뷰할 때 먼저 변경 목적을 한 줄로 적어요.",
         "isAuthor": true, "createdAt": "2026-11-24T07:30:00Z"]
    ]]

    private mutating func mutate(_ path: [String], method: String, body: Row) -> Any? {
        nextID += 1
        let id = String(nextID)
        let key = path.dropFirst().first ?? ""
        if path.first == "posts" {
            if method == "POST", path.count == 1 || key == "lightning" {
                var post = Self.post(id, body["category"] as? String ?? "LIGHTNING",
                                     body["title"] as? String ?? "", body["content"] as? String ?? "", author: 0)
                if key == "lightning" { post["lightningInfo"] = body }
                posts.insert(post, at: 0)
                return post
            }
            guard let index = posts.firstIndex(where: { $0["postId"] as? String == key })
            else { return nil }
            let route = Array(path.dropFirst(2))
            switch (method, route) {
            case ("PATCH", _):
                posts[index].merge(body) { _, new in new }
                if route == ["lightning"] { posts[index]["lightningInfo"] = body }
                return posts[index]
            case ("DELETE", []): posts.remove(at: index); return Row()
            case ("POST", ["like"]), ("POST", ["scrap"]):
                let like = route == ["like"]
                let field = like ? "isLiked" : "isScrapped"
                let count = like ? "likeCount" : "scrapCount"
                let enabled = posts[index][field] as? Bool != true
                posts[index][field] = enabled
                posts[index][count] = String(max(0, (Int(posts[index][count] as? String ?? "") ?? 0) + (enabled ? 1 : -1)))
                return [like ? "liked" : "scrapped": enabled]
            case ("POST", ["comments"]):
                var row = body
                row.merge(["commentId": id, "challengerName": "김유엠", "challengerNickname": "유엠",
                           "isAuthor": true, "createdAt": Date.now.ISO8601Format()]) { _, new in new }
                comments[key, default: []].append(row)
                posts[index]["commentCount"] = String(comments[key]?.count ?? 0)
                return row
            default:
                guard route.first == "comments", route.count >= 2,
                      let row = comments[key]?.firstIndex(where: { $0["commentId"] as? String == route[1] })
                else { return nil }
                if method == "DELETE" {
                    comments[key]?.remove(at: row)
                    posts[index]["commentCount"] = String(comments[key]?.count ?? 0)
                    return Row()
                }
                let liked = comments[key]?[row]["isLiked"] as? Bool != true
                comments[key]?[row]["isLiked"] = liked
                return ["liked": liked]
            }
        }
        if path.first == "notices" {
            if path.count == 1, method == "POST" {
                var row = Self.notice(id, body["title"] as? String ?? "", body["content"] as? String ?? "")
                row.merge(body) { _, new in new }
                row["authorMemberId"] = "101"
                row["author"] = ["nickname": "유엠"]
                notices.insert(row, at: 0)
                return ["noticeId": id]
            }
            guard let index = notices.firstIndex(where: { $0["id"] as? String == key }) else { return nil }
            switch Array(path.dropFirst(2)) {
            case []:
                if method == "DELETE" { notices.remove(at: index) }
                else { notices[index].merge(body) { _, new in new } }
            case ["reminders"], ["read"]: break
            case ["links"]:
                let links = body["links"] as? [String] ?? []
                notices[index]["links"] = links.enumerated().map { ["id": String($0.offset + 1), "url": $0.element] }
                notices[index]["hasLinks"] = !links.isEmpty
            default: return nil
            }
            return Row()
        }
        if path.starts(with: ["community", "threads"]) {
            let thread = Array(path.dropFirst(2))
            if thread.isEmpty, method == "POST" {
                var room = Self.room(id, body["category"] as? String ?? "FREE", body["icon"] as? String ?? "💬",
                                     body["title"] as? String ?? "", body["description"] as? String ?? "")
                room["myRole"] = "OWNER"
                rooms.insert(room, at: 0)
                return room
            }
            guard let index = rooms.firstIndex(where: { $0["threadId"] as? String == thread.first })
            else { return nil }
            switch Array(thread.dropFirst()) {
            case []:
                if method == "DELETE" { rooms.remove(at: index); return Row() }
                rooms[index].merge(body) { _, new in new }
            case ["pin"]: rooms[index]["isPinned"] = method == "POST"
            case ["mute"]: rooms[index]["isMuted"] = method == "POST"
            case ["leave"]:
                rooms[index]["membershipState"] = "LEFT"
                rooms[index]["isJoined"] = false
            default: return nil
            }
            return rooms[index]
        }
        if path.starts(with: ["member", "blocks"]), let member = path.last {
            if method == "POST" { blocked.insert(member) } else { blocked.remove(member) }
            return ["memberId": member, "isBlocked": method == "POST"] as Row
        }
        if path.starts(with: ["reports", "members"]), let member = path.last {
            return ["reportId": id, "memberId": member]
        }
        if path.starts(with: ["community", "messages"]), path.count == 4 {
            return ["reportId": id, "messageId": path[2]]
        }
        return nil
    }

    private static let people = [
        ["memberId": "101", "name": "김유엠", "nickname": "유엠", "part": "WEB"],
        ["memberId": "102", "name": "이서윤", "nickname": "윤", "part": "PLAN"],
        ["memberId": "103", "name": "박도현", "nickname": "도도", "part": "DESIGN"],
        ["memberId": "104", "name": "정하늘", "nickname": "하늘", "part": "WEB"]
    ]

    private static func matches(_ term: String?, in row: Row, fields: [String]) -> Bool {
        guard let term, !term.isEmpty else { return true }
        return fields.contains { (row[$0] as? String)?.localizedCaseInsensitiveContains(term) == true }
    }

    // MARK: - Notices

    private var notices: [Row] = {
        [
            notice("21", "데모데이 중간 발표 자료 제출 안내",
                   "금요일 오후 6시까지 팀별 발표 자료를 제출해 주세요. 발표는 5분, 질의응답은 3분입니다."),
            notice("22", "파트별 스터디 회고를 모아요",
                   "이번 달 가장 도움이 된 활동과 다음 달에 도전하고 싶은 주제를 남겨 주세요."),
            notice("23", "운영진 정기 회의 안건 접수",
                   "수요일까지 논의가 필요한 안건을 운영 회의 문서에 추가해 주세요.", tab: "CENTRAL_MEMBER"),
            notice("24", "교내 행사 장소 확인", "행사 장소와 입장 시간을 확인해 주세요.", tab: "SCHOOL_CORE"),
            notice("25", "파트별 출석 현황 점검", "이번 주 스터디 출석 기록을 확인해 주세요.",
                   tab: "SCHOOL_PART_LEADER")
        ]
    }()

    private static func notice(_ id: String, _ title: String, _ body: String,
                               tab: String = "CHALLENGER") -> Row {
        ["id": id, "title": title, "content": body, "createdAt": "2026-11-24T09:00:00Z",
         "mustRead": id == "21", "viewCount": "28", "authorMemberId": "102",
         "author": ["nickname": "윤", "organizationName": "중앙 운영진"],
         "targetInfo": ["targetGisuId": "10", "targetNoticeTab": tab, "targetParts": []],
         "hasImages": false, "hasLinks": false, "hasVote": false, "images": [], "links": []]
    }

    private func noticeResult(_ path: [String], _ query: [String: String]) -> Any? {
        if path.isEmpty || path == ["search"] {
            let rows = notices.filter { row in
                let target = row["targetInfo"] as? Row
                return (query["page"] ?? "0") == "0"
                    && target?["targetGisuId"].map { String(describing: $0) } == query["gisuId"]
                    && target?["targetNoticeTab"] as? String == query["noticeTab"]
                    && Self.matches(query["keyword"], in: row, fields: ["title", "content"])
            }
            return ["content": rows, "hasNext": false]
        }
        guard let entry = notices.first(where: { $0["id"] as? String == path.first }) else {
            return nil
        }
        switch Array(path.dropFirst()) {
        case []: return entry
        case ["read-statics"]: return ["totalCount": "3", "readCount": "2", "unreadCount": "1"]
        case ["read-status"]:
            let read = query["status"] == "READ"
            let subset = read ? Array(Self.people.prefix(2)) : [Self.people[2]]
            let readers = subset.map {
                ["challengerId": $0["memberId"]!, "name": $0["name"]!, "schoolName": "한빛대학교"]
            }
            return ["content": readers, "hasNext": false]
        default: return nil
        }
    }

    // MARK: - Post board

    private var posts: [Row] = {
        [
            post("31", "QUESTION", "스터디 코드 리뷰는 어떻게 진행하시나요?",
                 "이번 주부터 짝을 지어 리뷰할 예정이에요. 팀에서 쓰는 리뷰 방식이 궁금합니다.", author: 2),
            post("32", "FREE", "첫 팀 프로젝트 회고", "서로의 작업을 직접 시연하니 피드백이 구체적이었어요.", author: 0),
            post("33", "INFORMATION", "발표 전 점검할 항목을 공유해요",
                 "시연 계정과 네트워크 연결을 미리 확인하고, 예비 녹화본을 준비해 보세요.", author: 1),
            post("34", "HABIT", "하루 한 번 커밋 기록", "작은 단위로 테스트를 추가한 기록을 남겼어요.", author: 2),
            post("35", "LIGHTNING", "금요일에 함께 모각코해요", "학생회관 2층에서 각자 작업하다 만나요.", author: 3)
        ]
    }()

    private static func post(_ id: String, _ category: String, _ title: String,
                             _ body: String, author: Int) -> Row {
        let person = Self.people[author]
        var row: Row = [
            "postId": id, "category": category, "title": title, "content": body,
            "authorMemberId": person["memberId"]!, "authorName": person["name"]!,
            "authorNickname": person["nickname"]!, "createdAt": "2026-11-24T06:30:00Z",
            "writeTime": "2026-11-24T06:30:00Z", "likeCount": "4", "isLiked": id == "33",
            "scrapCount": "2", "isScrapped": id == "33", "commentCount": id == "31" ? "1" : "0"
        ]
        if category == "LIGHTNING" {
            row["lightningInfo"] = ["meetAt": "2026-11-27T09:00:00Z", "location": "학생회관 2층",
                                    "maxParticipants": "6", "openChatUrl": "https://preview.invalid/meet"]
        }
        return row
    }

    private func postResult(_ path: [String], _ query: [String: String]) -> Any? {
        let scope = path.first ?? ""
        if path.count <= 1 && ["", "my", "commented", "scrapped", "search"].contains(scope) {
            let rows = posts.filter {
                (scope != "my" || $0["authorMemberId"] as? String == "101")
                    && (scope != "scrapped" || $0["isScrapped"] as? Bool == true)
                    && (scope != "commented" || $0["postId"] as? String == "31")
                    && (query["category"] == nil || $0["category"] as? String == query["category"])
                    && Self.matches(query["keyword"], in: $0, fields: ["title", "content"])
            }
            let page = query["page"] ?? "0"
            return ["content": page == "0" ? rows : [], "page": page, "hasNext": false]
        }
        guard let row = posts.first(where: { $0["postId"] as? String == scope }) else { return nil }
        switch Array(path.dropFirst()) {
        case []: return row
        case ["comments"]:
            return comments[scope] ?? []
        default: return nil
        }
    }

    // MARK: - Threads

    private var rooms: [Row] = {
        [
            room("41", "STUDY", "📚", "웹 파트 스터디", "이번 주 워크북과 코드 리뷰 일정을 나눠요."),
            room("42", "PROJECT", "🛠️", "데모데이 준비방", "팀별 시연 순서와 리허설 시간을 맞춰요."),
            room("43", "FREE", "☕️", "라운지", "스터디가 끝나고 편하게 이야기해요."),
            room("44", "QNA", "💬", "챌린저 질문방", "활동 중 궁금한 점을 남겨 주세요.")
        ]
    }()

    private static func room(_ id: String, _ category: String, _ icon: String,
                             _ title: String, _ description: String) -> Row {
        ["threadId": id, "title": title, "description": description, "icon": icon, "category": category,
         "isPinned": id == "41", "isMuted": false, "isJoined": true, "membershipState": "ACTIVE",
         "myRole": id == "41" ? "OWNER" : "MEMBER", "memberCount": "3", "maxMembers": "100",
         "unreadCount": id == "42" ? "1" : "0"]
    }

    private func threadResult(_ path: [String], _ query: [String: String]) -> Any? {
        if path.isEmpty {
            let filter = query["filter"] ?? "all"
            let rows = rooms.filter {
                (filter == "all" || filter == $0["category"] as? String
                    || (filter == "unread" && $0["unreadCount"] as? String != "0"))
                    && Self.matches(query["q"], in: $0, fields: ["title", "description"])
            }
            let pinned = rows.filter { $0["isPinned"] as? Bool == true }
            let regular = rows.filter { $0["isPinned"] as? Bool == false }
            return ["pinned": pinned, "threads": regular.dropFirst(Self.offset(query)).map { $0 }]
        }
        guard let id = path.first, let room = rooms.first(where: { $0["threadId"] as? String == id })
        else { return nil }
        switch Array(path.dropFirst()) {
        case []: return room
        case ["messages"]:
            let text: [String]
            switch id {
            case "41": text = ["워크북 실습을 마쳤어요. 오늘 저녁에 리뷰할까요?", "좋아요! 저녁 7시에 만나요."]
            case "42": text = ["목요일 오후 5시에 발표 리허설을 진행할게요."]
            case "44": text = ["스터디 기록은 활동 탭에서 확인할 수 있어요."]
            default: text = []
            }
            let rows: [Row] = text.enumerated().map { index, content in
                let sender = Self.people[index == 0 ? 1 : 0]
                return ["messageId": id + String(index), "content": content,
                        "senderId": sender["memberId"]!, "senderName": sender["nickname"]!,
                        "createdAt": "2026-11-24T08:0" + String(index) + ":00Z",
                        "isSenderBlocked": false, "files": [], "reactions": index == 0 ? [
                            ["emoji": "👍", "count": "2", "reactedByMe": false] as Row
                        ] : []]
            }
            let before = Int(query["before"] ?? "") ?? Int.max
            return ["messages": rows.reversed().filter {
                Int($0["messageId"] as? String ?? "") ?? 0 < before
            }, "hasMore": false]
        case ["members"], ["invitable"]:
            let inviting = path.last == "invitable"
            let candidates = inviting ? Array(Self.people.suffix(1)) : Array(Self.people.prefix(3))
            let rows = candidates.filter { Self.matches(query["q"], in: $0, fields: ["name", "nickname"]) }
                .map { person in
                    var row = person
                    row["generation"] = "10"
                    if !inviting {
                        let owner = id == "41" ? "101" : "102"
                        row["role"] = person["memberId"] == owner ? "OWNER" : "MEMBER"
                        row["state"] = "ACTIVE"
                    }
                    return row
                }
            return ["items": Array(rows.dropFirst(Self.offset(query))), "total": String(rows.count)]
        default: return nil
        }
    }

    private static func offset(_ query: [String: String]) -> Int {
        max(0, Int(query["offset"] ?? "") ?? 0)
    }
}
