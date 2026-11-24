//
//  AuthReleaseCatalog.swift
//  AuthPresentation
//
//  Created by euijjang97 on 11/23/26.
//

import Foundation
import UMCFoundation

struct AuthReleaseVersion: Comparable {
    let version: String
    let build: Int

    init?(version: String, build: String) {
        let components = version.split(separator: ".", omittingEmptySubsequences: false)
        guard components.count == 3,
              components.allSatisfy({ !$0.isEmpty && $0.allSatisfy(\.isASCIIDigit) }),
              build.allSatisfy(\.isASCIIDigit), let number = Int(build), number > 0 else {
            return nil
        }
        self.version = version
        self.build = number
    }

    static func < (lhs: Self, rhs: Self) -> Bool {
        let order = lhs.version.compare(rhs.version, options: .numeric)
        return order == .orderedSame ? lhs.build < rhs.build : order == .orderedAscending
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.build == rhs.build
            && lhs.version.compare(rhs.version, options: .numeric) == .orderedSame
    }
}

private extension Character {
    var isASCIIDigit: Bool { isASCII && isNumber }
}

struct AuthReleaseCatalog {
    struct Release {
        let version: AuthReleaseVersion
        let notes: URL
    }

    static func releases(in page: Data) throws -> (count: Int, valid: [Release]) {
        let releases = try JSONDecoder().decode([PublishedRelease].self, from: page)
        return (releases.count, releases.compactMap(\.verified))
    }

    // The publisher embeds the same manifest in release.json and the release body's JSON block.
    static func latest(session: URLSession = .shared) async throws -> Release {
        let endpoint = URL(
            string: "https://api.github.com/repos/UMC-PRODUCT/umc-product-macOS/releases"
        )!
        var latest: Release?
        var page = 1
        while true {
            try Task.checkCancellation()
            let url = endpoint.appending(queryItems: [
                URLQueryItem(name: "per_page", value: "100"),
                URLQueryItem(name: "page", value: String(page)),
            ])
            var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData)
            request.timeoutInterval = 20
            request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
            let (data, response) = try await session.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }
            let releases = try releases(in: data)
            for release in releases.valid {
                if latest.map({ $0.version < release.version }) ?? true { latest = release }
            }
            if releases.count < 100 { break }
            page += 1
        }
        guard let latest else { throw URLError(.cannotParseResponse) }
        return latest
    }
}

private struct PublishedRelease: Codable {
    let tag: String
    let draft: Bool
    let body: String
    let assets: [ReleaseAsset]

    enum CodingKeys: String, CodingKey {
        case tag = "tag_name"
        case draft, body, assets
    }

    init(from decoder: Decoder) throws {
        let fields = try decoder.container(keyedBy: CodingKeys.self)
        tag = try fields.decode(String.self, forKey: .tag)
        draft = try fields.decode(Bool.self, forKey: .draft)
        body = try fields.decodeIfPresent(String.self, forKey: .body) ?? ""
        assets = try fields.decode([ReleaseAsset].self, forKey: .assets)
    }

    func encode(to encoder: Encoder) throws {
        var fields = encoder.container(keyedBy: CodingKeys.self)
        try fields.encode(tag, forKey: .tag)
        try fields.encode(draft, forKey: .draft)
        try fields.encode(body, forKey: .body)
        try fields.encode(assets, forKey: .assets)
    }

    var verified: AuthReleaseCatalog.Release? {
        let base = "https://github.com/UMC-PRODUCT/umc-product-macOS/releases"
        let parts = tag.dropFirst().components(separatedBy: "-build.")
        guard !draft, tag.first == "v", parts.count == 2,
              let version = AuthReleaseVersion(version: parts[0], build: parts[1]),
              let start = body.range(of: "```json"),
              let end = body.range(of: "```", range: start.upperBound..<body.endIndex),
              let manifest = try? JSONDecoder().decode(
                ReleaseManifest.self, from: Data(body[start.upperBound..<end.lowerBound].utf8)
              ),
              manifest.status == "available", manifest.version == version.version,
              manifest.notesURL == "\(base)/tag/\(tag)",
              let notes = URL(string: manifest.notesURL) else { return nil }

        let prefix = "\(base)/download/\(tag)/"
        let dmg = "UMC-Desk-\(version.version)-build\(version.build).dmg"
        guard manifest.dmgURL == prefix + dmg,
              assets.contains(where: { $0.matches(name: "release.json", prefix: prefix) }),
              assets.contains(where: { $0.matches(name: dmg, prefix: prefix)
                  && $0.size == manifest.size }) else { return nil }

        return AuthReleaseCatalog.Release(version: version, notes: notes)
    }
}

private struct ReleaseAsset: Codable {
    let name: String
    let url: String
    let state: String
    let size: String

    enum CodingKeys: String, CodingKey {
        case name, state, size
        case url = "browser_download_url"
    }

    init(from decoder: Decoder) throws {
        let fields = try decoder.container(keyedBy: CodingKeys.self)
        name = try fields.decode(String.self, forKey: .name)
        state = try fields.decode(String.self, forKey: .state)
        url = try fields.decode(String.self, forKey: .url)
        size = try fields.decodeFlexibleString(forKey: .size)
    }

    func encode(to encoder: Encoder) throws {
        var fields = encoder.container(keyedBy: CodingKeys.self)
        try fields.encode(name, forKey: .name)
        try fields.encode(state, forKey: .state)
        try fields.encode(url, forKey: .url)
        try fields.encode(size, forKey: .size)
    }

    func matches(name expected: String, prefix: String) -> Bool {
        name == expected && url == prefix + expected && state == "uploaded" && (Int(size) ?? 0) > 0
    }
}

private struct ReleaseManifest: Codable {
    let status: String
    let version: String
    let dmgURL: String
    let notesURL: String
    let size: String

    enum CodingKeys: String, CodingKey {
        case status, version
        case dmgURL = "dmgUrl"
        case notesURL = "notesUrl"
        case size = "sizeBytes"
    }

    init(from decoder: Decoder) throws {
        let fields = try decoder.container(keyedBy: CodingKeys.self)
        status = try fields.decode(String.self, forKey: .status)
        version = try fields.decode(String.self, forKey: .version)
        dmgURL = try fields.decode(String.self, forKey: .dmgURL)
        notesURL = try fields.decode(String.self, forKey: .notesURL)
        size = try fields.decodeFlexibleString(forKey: .size)
    }

    func encode(to encoder: Encoder) throws {
        var fields = encoder.container(keyedBy: CodingKeys.self)
        try fields.encode(status, forKey: .status)
        try fields.encode(version, forKey: .version)
        try fields.encode(dmgURL, forKey: .dmgURL)
        try fields.encode(notesURL, forKey: .notesURL)
        try fields.encode(size, forKey: .size)
    }
}
