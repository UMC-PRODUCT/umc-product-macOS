//
//  DeskPreviewWorkData.swift
//  UMCDesk
//
//  Created by euijjang97 on 11/25/26.
//

import Foundation

struct DeskPreviewWorkData {
    private typealias Row = [String: Any]

    private struct Member {
        let id: String
        let name: String
        let nickname: String
        let part: String
        let school: String

        var row: [String: String] {
            ["memberId": id, "memberName": name, "name": name, "nickname": nickname,
             "schoolName": school, "gisu": "10", "part": part]
        }
    }

    private static let members = [
        Member(id: "101", name: "김유엠", nickname: "유엠", part: "WEB", school: "한빛대학교"),
        Member(id: "102", name: "서하늘", nickname: "하늘", part: "DESIGN", school: "한빛대학교"),
        Member(id: "103", name: "윤지우", nickname: "지우", part: "SPRINGBOOT", school: "한빛대학교"),
        Member(id: "104", name: "박도윤", nickname: "도윤", part: "PLAN", school: "한빛대학교"),
        Member(id: "105", name: "최지우", nickname: "지니", part: "WEB", school: "가온대학교")
    ]
    private let projects: [(id: String, name: String)]
    private let includesSamples: Bool

    private static let sampleProjects = [(id: "1", name: "모아"), (id: "3", name: "사이")]
    private let anchor = Date.now
    private var addedSchedules: [Row] = []
    private var statuses: [String: String] = [:]
    private var reviewedStatus = "PRESENT_PENDING"
    private var names = ["301": "웹 파트 스터디", "302": "프로젝트 리뷰 모임"]
    private var mentors = ["301": ["101"], "302": ["101"]]
    private var attendees = ["301": ["105"], "302": ["102", "103", "104"]]
    private var points: [String: [Row]] = [:]
    private var nextID = 2000

    init(isEmpty: Bool) {
        includesSamples = !isEmpty
        projects = isEmpty ? [] : Self.sampleProjects
        if isEmpty {
            names = [:]
            mentors = [:]
            attendees = [:]
        }
    }

    mutating func result(for request: URLRequest) -> Any? {
        guard let url = request.url else { return nil }
        let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        func query(_ key: String) -> String? { queryItems.first { $0.name == key }?.value }
        let path = url.path

        if request.httpMethod == "POST", path == "/api/v1/authorization/resource-permissions/batch" {
            guard includesSamples else { return ["results": [Row]()] }
            return ["results": [["resourceId": "801", "permissions": [
                ["permissionType": "APPROVE", "hasPermission": true]
            ]]]]
        }
        if request.httpMethod != "GET" {
            guard path.hasPrefix("/api/v2/schedules") || path.hasPrefix("/api/v1/study-groups")
                    || path.hasPrefix("/api/v1/challenger/") else { return nil }
            return mutate(path: path, request: request)
        }
        switch path {
        case "/api/v2/schedules/me":
            return schedules(from: query("from"), to: query("to"),
                             tracked: query("isAttendanceRequired") == "true")
        case "/api/v2/schedules/capabilities":
            return ["canCreateSchedule": true, "canCreateAttendanceRequiredSchedule": true,
                    "maxParticipantCount": "50"] as Row
        case "/api/v2/schedules/attendance":
            guard includesSamples else { return [Row]() }
            return [["scheduleId": "801", "name": "웹 파트 코드 리뷰",
                     "participants": [
                        ["memberId": "105", "name": "최지우", "attendanceStatus": reviewedStatus],
                        ["memberId": "102", "name": "서하늘", "attendanceStatus": "PRESENT"]
                     ]] as Row]
        case "/api/v2/curriculums/progress/me":
            let weeks = includesSamples ? [
                ("컴포넌트 설계", "추천 상품 카드 나누기"), ("상태 관리", "검색 요청 취소하기"),
                ("서버 데이터 연결", "페이지 단위로 목록 불러오기"), ("접근성 점검", "키보드만으로 주문하기")
            ] : []
            return ["weeks": weeks.enumerated().map { index, week -> Row in
                ["weeklyCurriculumId": String(501 + index), "weekNo": String(index + 1),
                 "title": week.0, "originalWorkbooks": [["title": week.1]]]
            }]
        case "/api/v1/study-groups/names":
            return ["studyGroups": names.keys.sorted().map { ["groupId": $0, "name": names[$0]!] }]
        case _ where path.hasPrefix("/api/v1/study-groups/"):
            let id = url.lastPathComponent
            guard names[id] != nil else { return nil }
            return ["mentors": Self.members.filter { mentors[id]?.contains($0.id) == true }.map(\.row),
                    "members": Self.members.filter { attendees[id]?.contains($0.id) == true }.map(\.row)]
        case _ where path.hasPrefix("/api/v1/challenger/"):
            let id = url.lastPathComponent
            let records = points[id] ?? []
            return ["challengerId": id, "points": records,
                    "totalPoints": records.reduce(0) { $0 + ($1["point"] as? Int ?? 0) }] as Row
        case "/api/v1/authorization/resource-permission":
            guard let resource = query("resourceType"),
                  ["ATTENDANCE", "STUDY_GROUP", "CHALLENGER_POINT"].contains(resource),
                  let operation = query("permissionType") else { return nil }
            return ["permissions": [["permissionType": operation, "hasPermission": true] as Row]]
        case "/api/v1/member/search" where query("size") == "30":
            let keyword = query("keyword") ?? ""
            let part = query("part")
            let candidates = includesSamples || query("gisuId") == nil ? Self.members : []
            let rows = candidates.filter { member in
                (part == nil || member.part == part) &&
                (keyword.isEmpty || member.name.contains(keyword) || member.nickname.contains(keyword))
            }
            return ["page": ["content": rows.map(\.row), "hasNext": false] as Row]
        case "/api/v1/projects/me/managed" where query("size") == "1":
            return ["content": projects.prefix(1).map { ["id": $0.id, "name": $0.name] }]
        case "/api/v1/projects/me/applications":
            guard query("status") == nil || query("status") == "APPROVED" else { return [Row]() }
            return projects.map { project -> Row in
                ["projectId": project.id, "status": "APPROVED",
                 "project": ["name": project.name, "partQuotas": []] as Row,
                 "matchingRound": ["type": "PLAN_DEVELOPER", "phase": "RANDOM_MATCHING"]]
            }
        case "/api/v1/projects/members":
            let ids = queryItems.filter { $0.name == "projectIds" }
                .flatMap { ($0.value ?? "").components(separatedBy: ",") }
            var teams: [String: Row] = [:]
            for project in projects where ids.contains(project.id) {
                teams[project.id] = ["projectId": project.id, "productOwner": Self.members[3].row,
                                     "coProductOwners": [], "partGroups": [
                                        ["part": "WEB", "members": [Self.members[0].row, Self.members[4].row]]
                                     ]]
            }
            return teams
        default:
            guard path.hasPrefix("/api/v1/member/profile/"),
                  let member = Self.members.first(where: { $0.id == url.lastPathComponent })
            else { return nil }
            return ["id": member.id, "name": member.name, "nickname": member.nickname,
                    "schoolName": member.school,
                    "challengerRecords": [
                        ["challengerId": member.id, "gisuId": "10", "gisu": "10", "part": member.part]
                    ]] as Row
        }
    }

    private mutating func mutate(path: String, request: URLRequest) -> Any? {
        nextID += 1
        let id = String(nextID)
        let json = DataPreviewFixtures.json(request)
        let body = json as? Row ?? [:]
        let route = path.split(separator: "/").map(String.init)
        if path == "/api/v2/schedules" {
            var row = body
            row["scheduleId"] = id
            row["isOnline"] = body["location"] == nil
            row["isParticipant"] = true
            row["isAttendanceChecked"] = body["attendancePolicy"] != nil
            addedSchedules.append(row)
            return id
        }
        if route.starts(with: ["api", "v2", "schedules"]), route.count == 6 {
            let schedule = route[3]
            if route.last == "decide" {
                let decision = json as? [[String: Any]]
                reviewedStatus = decision?.first?["isApproved"] as? Bool == true ? "PRESENT" : "ABSENT"
                return [["status": reviewedStatus]]
            }
            let status = route.last == "excuse" ? "EXCUSED_PENDING" : "PRESENT_PENDING"
            statuses[schedule] = status
            return ["status": status]
        }
        if path == "/api/v1/study-groups/schedules" { return id }
        if route.starts(with: ["api", "v1", "study-groups"]) {
            let group = route.count > 3 ? route[3] : id
            if let name = body["name"] as? String {
                names[group] = name
                if let ids = body["mentorIds"] as? [Int] { mentors[group] = ids.map(String.init) }
                if let ids = body["memberIds"] as? [Int] { attendees[group] = ids.map(String.init) }
            } else if route.count == 6 {
                let member = route[5]
                mentors[group]?.removeAll { $0 == member }
                attendees[group]?.removeAll { $0 == member }
                if route[4] == "mentors" { mentors[group, default: []].append(member) }
                else { attendees[group, default: []].append(member) }
            } else { return nil }
            return Row()
        }
        if route.count == 5, route.last == "points" {
            let member = route[3]
            points[member, default: []].append(["id": id, "challengerId": member,
                "pointType": "CUSTOM", "point": body["pointValue"] ?? 0,
                "description": body["description"] ?? ""])
            return ["challengerId": member]
        }
        return nil
    }

    private func schedules(from: String?, to: String?, tracked: Bool) -> [Row] {
        let calendar = Calendar.current
        let start = max(calendar.startOfDay(for: anchor), anchor.addingTimeInterval(-180))
        let entries: [(id: String, name: String, day: Int, online: Bool, status: String?)] =
            tracked ? [
                ("801", "웹 파트 코드 리뷰", 0, true, nil),
                ("802", "중간 발표 리허설", 0, false, nil),
                ("803", "스터디 회고", -3, true, "PRESENT")
            ] : [("804", "기획·개발 싱크업", 1, true, nil)]
        let lower = from.flatMap { try? Date.ISO8601FormatStyle().parse($0) }
        let upper = to.flatMap { try? Date.ISO8601FormatStyle().parse($0) }
        let seeded = (includesSamples ? entries : []).compactMap { entry -> Row? in
            guard let date = calendar.date(byAdding: .day, value: entry.day, to: start)
            else { return nil }
            let end = date.addingTimeInterval(3600)
            guard end >= (lower ?? .distantPast), date <= (upper ?? .distantFuture)
            else { return nil }
            var row: Row = ["scheduleId": entry.id, "name": entry.name,
                            "startsAt": date.ISO8601Format(), "endsAt": end.ISO8601Format(),
                            "isOnline": entry.online, "isParticipant": true,
                            "isAttendanceChecked": tracked]
            row["attendanceStatus"] = statuses[entry.id] ?? entry.status
            if tracked {
                row["attendancePolicy"] = [
                    "checkInStartAt": date.addingTimeInterval(-600).ISO8601Format(),
                    "onTimeEndAt": date.addingTimeInterval(1200).ISO8601Format(),
                    "lateEndAt": date.addingTimeInterval(2700).ISO8601Format()
                ]
            }
            if !entry.online {
                row["location"] = ["locationName": "학생회관 세미나실",
                                   "latitude": 37.55, "longitude": 127.04] as Row
            }
            return row
        }
        return seeded + addedSchedules.compactMap { row in
            guard row["isAttendanceChecked"] as? Bool == tracked,
                  let start = row["startsAt"] as? String, let end = row["endsAt"] as? String,
                  let date = try? Date.ISO8601FormatStyle().parse(start),
                  let finish = try? Date.ISO8601FormatStyle().parse(end),
                  finish >= (lower ?? .distantPast), date <= (upper ?? .distantFuture)
            else { return nil }
            var updated = row
            updated["attendanceStatus"] = statuses[row["scheduleId"] as? String ?? ""]
            return updated
        }
    }
}
