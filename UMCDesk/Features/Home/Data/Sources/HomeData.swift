//
//  HomeData.swift
//  HomeData
//
//  Created by euijjang97 on 11/23/26.
//

import CoreNetwork
import Foundation
import HomeDomain

public struct LiveHomeRepository: HomeRepository {
    private let client: NetworkClient
    private let baseURL: URL

    public init(client: NetworkClient, baseURL: URL) {
        self.client = client
        self.baseURL = baseURL
    }

    public func profile() async throws -> HomeProfile {
        let profile: ProfileDTO = try await request("api/v1/member/me")
        return HomeProfile(id: profile.id, nickname: profile.nickname)
    }

    public func schedule() async throws -> String? {
        let today = Calendar.current.startOfDay(for: .now)
        guard let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) else {
            throw URLError(.badURL)
        }
        func list(requiresAttendance: Bool) async throws -> [ScheduleDTO] {
            let query = [
                URLQueryItem(name: "from", value: today.ISO8601Format()),
                URLQueryItem(name: "to", value: tomorrow.addingTimeInterval(-1).ISO8601Format()),
                URLQueryItem(name: "isAttendanceRequired", value: String(requiresAttendance)),
            ]
            return try await request("api/v2/schedules/me", query: query)
        }
        async let tracked = list(requiresAttendance: true)
        async let other = list(requiresAttendance: false)
        return try await (tracked + other).min { $0.startsAt < $1.startsAt }?.name
    }

    public func notice() async throws -> String? {
        let gisu: GisuDTO = try await request("api/v1/gisu/active")
        let page: PageDTO<NoticeDTO> = try await request(
            "api/v1/notices",
            query: [
                URLQueryItem(name: "gisuId", value: gisu.gisuId),
                URLQueryItem(name: "noticeTab", value: "CHALLENGER"),
                URLQueryItem(name: "size", value: "1"),
            ])
        return page.content.first?.title
    }

    public func project() async throws -> String? {
        let gisu: GisuDTO = try await request("api/v1/gisu/active")
        let page: PageDTO<ProjectDTO> = try await request(
            "api/v1/projects/me/managed",
            query: [
                URLQueryItem(name: "gisuId", value: gisu.gisuId),
                URLQueryItem(name: "size", value: "1"),
            ])
        return page.content.first?.name
    }

    private func request<T: Codable>(
        _ path: String,
        query: [URLQueryItem] = []
    ) async throws -> T {
        var url = baseURL.appending(path: path)
        if !query.isEmpty { url.append(queryItems: query) }
        let (data, _) = try await client.request(URLRequest(url: url))
        return try JSONDecoder().decode(APIResponse<T>.self, from: data).unwrap()
    }
}
