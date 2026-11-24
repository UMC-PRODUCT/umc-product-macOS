//
//  AuthPublishedTermsTests.swift
//  AuthPresentationTests
//
//  Created by euijjang97 on 11/23/26.
//

import AuthDomain
import Foundation
import Testing
@testable import AuthPresentation

struct AuthPublishedTermsTests {
    @Test("The requested category uses the wire type and opens only its published link")
    func publishedByType() async {
        let service = URL(string: "https://umc.example/service")!
        let privacy = URL(string: "https://umc.example/privacy")!
        let terms = [
            term("MARKETING", title: "서비스 이용약관", link: "https://umc.example/other"),
            term("PRIVACY", title: "Privacy", link: privacy.absoluteString),
            term("SERVICE", title: "서비스", link: service.absoluteString),
        ]
        let loadedService = await PublishedTermState.load(requested: .service) { terms }
        #expect(loadedService == .published(service))
        let loadedPrivacy = await PublishedTermState.load(requested: .privacy) { terms }
        #expect(loadedPrivacy == .published(privacy))
    }

    @Test("Older responses match only the exact server description")
    func legacyDescription() async {
        let privacy = URL(string: "https://umc.example/privacy")!
        let terms = [
            term(nil, title: "위치기반 서비스 이용약관", link: "https://umc.example/location"),
            term(nil, title: "개인정보 처리방침", link: privacy.absoluteString),
        ]
        #expect(await PublishedTermState.load(requested: .service) { terms } == .unpublished)
        let loadedPrivacy = await PublishedTermState.load(requested: .privacy) { terms }
        #expect(loadedPrivacy == .published(privacy))
    }

    @Test("Retrieving terms again can recover from a server error or an empty list")
    func retry() async {
        let failed = await PublishedTermState.load(requested: .service) {
            throw URLError(.notConnectedToInternet)
        }
        #expect(failed == .failed)
        #expect(await PublishedTermState.load(requested: .service) { [] } == .unpublished)
        let url = URL(string: "https://umc.example/service")!
        let result = await PublishedTermState.load(requested: .service) {
            [term("SERVICE", title: "서비스 이용약관", link: url.absoluteString)]
        }
        #expect(result == .published(url))
    }

    @Test("Unusable links remain retryable", arguments: [
        "", "/terms", "file:///tmp/internal-draft", "https://", "https://user@umc.example/doc",
    ])
    func unusableLinks(link: String) async {
        let result = await PublishedTermState.load(requested: .service) {
            [term("SERVICE", title: "서비스 이용약관", link: link)]
        }
        #expect(result == .failed)
    }

    private func term(_ type: String?, title: String, link: String) -> RegistrationTerm {
        RegistrationTerm(id: link, title: title, link: link, isMandatory: true, type: type)
    }
}
