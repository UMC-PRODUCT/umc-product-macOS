//
//  DataPreviewFixtures.swift
//  UMCDesk
//
//  Created by euijjang97 on 11/25/26.
//

import Foundation

/// URLProtocol is constructed by Foundation. The unique host binds it to one local session.
final class DataPreviewFixtures: @unchecked Sendable {
    private static let lock = NSLock()
    nonisolated(unsafe) private static let sessions = NSMapTable<NSString, DataPreviewFixtures>(
        keyOptions: .strongMemory, valueOptions: .weakMemory)
    let baseURL: URL
    private let lock = NSLock()
    private var community: DeskPreviewCommunityData
    private var work: DeskPreviewWorkData

    init(isEmpty: Bool = false) {
        community = DeskPreviewCommunityData(isEmpty: isEmpty)
        work = DeskPreviewWorkData(isEmpty: isEmpty)
        let host = UUID().uuidString.lowercased() + ".preview.invalid"
        baseURL = URL(string: "https://" + host)!
        Self.lock.withLock { Self.sessions.setObject(self, forKey: host as NSString) }
    }

    static func data(for request: URLRequest) throws -> Data {
        guard let url = request.url, url.scheme == "https", let host = url.host,
              url.user == nil, url.password == nil, url.port == nil,
              let session = lock.withLock({ sessions.object(forKey: host as NSString) })
        else { throw URLError(.unsupportedURL) }
        return try session.lock.withLock {
            guard let result = commonResult(for: request)
                ?? session.work.result(for: request)
                ?? session.community.result(for: request)
            else { throw URLError(.resourceUnavailable) }
            return try JSONSerialization.data(withJSONObject: ["success": true, "result": result])
        }
    }

    static func json(_ request: URLRequest) -> Any? {
        var bytes = request.httpBody ?? Data()
        if bytes.isEmpty, let stream = request.httpBodyStream {
            stream.open()
            defer { stream.close() }
            var buffer = [UInt8](repeating: 0, count: 4096)
            while true {
                let count = stream.read(&buffer, maxLength: buffer.count)
                guard count > 0 else { break }
                bytes.append(contentsOf: buffer.prefix(count))
            }
        }
        return try? JSONSerialization.jsonObject(with: bytes)
    }

    private static func commonResult(for request: URLRequest) -> Any? {
        guard request.httpMethod == "GET" else { return nil }
        let role = ["challengerId": "101", "gisuId": "10", "gisu": "10",
                    "roleType": "CENTRAL_OPERATING_TEAM_MEMBER"]
        switch request.url?.path {
        case "/api/v1/terms":
            return ["terms": [
                ["id": "1", "type": "SERVICE", "typeDescription": "서비스 이용약관",
                 "isMandatory": true, "link": "https://preview.invalid/terms/service"] as [String: Any],
                ["id": "2", "type": "PRIVACY", "typeDescription": "개인정보 처리방침",
                 "isMandatory": true, "link": "https://preview.invalid/terms/privacy"] as [String: Any]
            ]]
        case "/api/v1/member/me":
            return ["id": "101", "name": "김유엠", "nickname": "유엠",
                    "email": "umc@preview.invalid", "schoolName": "한빛대학교",
                    "roles": [role], "profile": [String: String](),
                    "challengerRecords": [["challengerId": "101", "gisuId": "10", "gisu": "10",
                                           "part": "WEB", "roles": [role]]]]
        case "/api/v2/member/me":
            return ["isSuperAdmin": false, "currentGisuMemberInfo": [
                "gisuId": "10", "isAdmin": true, "roleTypes": ["CENTRAL_OPERATING_TEAM_MEMBER"]
            ]]
        case "/api/v1/gisu/active":
            return ["gisuId": "10", "generation": "10"]
        case "/api/v2/gisu":
            return ["gisus": [["gisuId": "10", "generation": "10",
                               "chapters": [["chapterId": "1", "chapterName": "한빛 지부"]],
                               "schools": [["schoolId": "1", "schoolName": "한빛대학교"],
                                           ["schoolId": "2", "schoolName": "가온대학교"]]]]]
        default: return nil
        }
    }
}
