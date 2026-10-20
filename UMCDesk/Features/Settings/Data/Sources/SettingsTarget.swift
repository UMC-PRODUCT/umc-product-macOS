//
//  SettingsTarget.swift
//  SettingsData
//
//  Created by euijjang97 on 10/20/26.
//

import CoreNetwork
import Moya
import SettingsDomain

struct SettingsTarget: BaseTargetType {
    enum Endpoint {
        case profile
        case updateLinks(SettingsLinksRequest)
        case register(SettingsCodeRequest)
        case logout(SettingsLogoutRequest)
    }

    let environment: NetworkEnvironment
    let endpoint: Endpoint

    var path: String {
        switch endpoint {
        case .profile: "/api/v1/member/me"
        case .updateLinks: "/api/v1/member/profile/links"
        case .register: "/api/v1/challenger-record/member"
        case .logout: "/api/v1/auth/logout"
        }
    }

    var method: Moya.Method {
        switch endpoint {
        case .profile: .get
        case .updateLinks: .patch
        case .register, .logout: .post
        }
    }

    var task: Moya.Task {
        switch endpoint {
        case .profile: .requestPlain
        case .updateLinks(let body): .requestJSONEncodable(body)
        case .register(let body): .requestJSONEncodable(body)
        case .logout(let body): .requestJSONEncodable(body)
        }
    }
}

struct SettingsLinksRequest: Encodable {
    struct Link: Encodable {
        let type: String
        let link: String
    }
    let links: [Link]

    init(links: SettingsProfileLinks) {
        self.links = SettingsLinkKind.allCases.compactMap { kind in
            links[kind].isEmpty ? nil : Link(type: kind.rawValue, link: links[kind])
        }
    }
}

struct SettingsCodeRequest: Encodable { let code: String }
struct SettingsLogoutRequest: Encodable { let refreshToken: String }
