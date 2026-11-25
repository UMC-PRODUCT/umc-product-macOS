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
    private static let projects = [(id: "1", name: "모아"), (id: "3", name: "사이")]
    private static var anchor: Date { .now }

    func result(for request: URLRequest) -> Any? {
        guard let url = request.url else { return nil }
        let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        func query(_ key: String) -> String? { queryItems.first { $0.name == key }?.value }
        let path = url.path

        if request.httpMethod == "POST", path == "/api/v1/authorization/resource-permissions/batch" {
            return ["results": [["resourceId": "801", "permissions": [
                ["permissionType": "APPROVE", "hasPermission": true]
            ]]]]
        }
        guard request.httpMethod == "GET" else { return nil }
        switch path {
        case "/api/v2/schedules/me":
            return Self.schedules(from: query("from"), to: query("to"),
                             tracked: query("isAttendanceRequired") == "true")
        case "/api/v2/schedules/capabilities":
            return ["canCreateSchedule": true, "canCreateAttendanceRequiredSchedule": true,
                    "maxParticipantCount": "50"] as Row
        case "/api/v2/schedules/attendance":
            return [["scheduleId": "801", "name": "웹 파트 코드 리뷰",
                     "participants": [
                        ["memberId": "105", "name": "최지우", "attendanceStatus": "PRESENT_PENDING"],
                        ["memberId": "102", "name": "서하늘", "attendanceStatus": "PRESENT"]
                     ]] as Row]
        case "/api/v2/curriculums/progress/me":
            let titles = ["컴포넌트 설계", "상태 관리", "서버 데이터 연결", "접근성 점검"]
            return ["weeks": titles.enumerated().map { index, title -> Row in
                ["weeklyCurriculumId": String(501 + index), "weekNo": String(index + 1),
                 "title": title, "originalWorkbooks": [["title": title + " 실습 노트"]]]
            }]
        case "/api/v1/study-groups/names":
            return ["studyGroups": [["groupId": "301", "name": "웹 파트 스터디"],
                                    ["groupId": "302", "name": "프로젝트 리뷰 모임"]]]
        case "/api/v1/study-groups/301", "/api/v1/study-groups/302":
            let peers = path.hasSuffix("/301") ? [Self.members[4]] : [Self.members[1], Self.members[2], Self.members[3]]
            return ["mentors": [Self.members[0].row], "members": peers.map(\.row)]
        case "/api/v1/authorization/resource-permission":
            guard let resource = query("resourceType"),
                  ["ATTENDANCE", "STUDY_GROUP", "CHALLENGER_POINT"].contains(resource),
                  let operation = query("permissionType") else { return nil }
            return ["permissions": [["permissionType": operation, "hasPermission": true] as Row]]
        case "/api/v1/member/search" where query("size") == "30":
            let keyword = query("keyword") ?? ""
            let part = query("part")
            let rows = Self.members.filter { member in
                (part == nil || member.part == part) &&
                (keyword.isEmpty || member.name.contains(keyword) || member.nickname.contains(keyword))
            }
            return ["page": ["content": rows.map(\.row), "hasNext": false] as Row]
        case "/api/v1/projects/me/managed" where query("size") == "1":
            return ["content": [["id": Self.projects[0].id, "name": Self.projects[0].name]]]
        case "/api/v1/projects/me/applications":
            guard query("status") == nil || query("status") == "APPROVED" else { return [Row]() }
            return Self.projects.map { project -> Row in
                ["projectId": project.id, "status": "APPROVED",
                 "project": ["name": project.name, "partQuotas": []] as Row,
                 "matchingRound": ["type": "PLAN_DEVELOPER", "phase": "RANDOM_MATCHING"]]
            }
        case "/api/v1/projects/members":
            let ids = queryItems.filter { $0.name == "projectIds" }
                .flatMap { ($0.value ?? "").components(separatedBy: ",") }
            var teams: [String: Row] = [:]
            for project in Self.projects where ids.contains(project.id) {
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

    private static func schedules(from: String?, to: String?, tracked: Bool) -> [Row] {
        let calendar = Calendar.current
        let start = max(calendar.startOfDay(for: anchor), anchor.addingTimeInterval(-180))
        let entries: [(id: String, name: String, day: Int, online: Bool, status: String?)] =
            tracked ? [
                ("801", "웹 파트 코드 리뷰", 0, true, nil),
                ("802", "중간 발표 리허설", 2, false, nil),
                ("803", "스터디 회고", -3, true, "PRESENT")
            ] : [("804", "기획·개발 싱크업", 1, true, nil)]
        let lower = from.flatMap { try? Date.ISO8601FormatStyle().parse($0) }
        let upper = to.flatMap { try? Date.ISO8601FormatStyle().parse($0) }
        return entries.compactMap { entry -> Row? in
            guard let date = calendar.date(byAdding: .day, value: entry.day, to: start)
            else { return nil }
            let end = date.addingTimeInterval(3600)
            guard end >= (lower ?? .distantPast), date <= (upper ?? .distantFuture)
            else { return nil }
            var row: Row = ["scheduleId": entry.id, "name": entry.name,
                            "startsAt": date.ISO8601Format(), "endsAt": end.ISO8601Format(),
                            "isOnline": entry.online, "isParticipant": true,
                            "isAttendanceChecked": tracked]
            row["attendanceStatus"] = entry.status
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
    }
}
