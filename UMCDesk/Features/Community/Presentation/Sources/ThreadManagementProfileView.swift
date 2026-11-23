//
//  ThreadManagementProfileView.swift
//  CommunityPresentation
//
//  Created by euijjang97 on 11/23/26.
//

import CommunityDomain
import CoreDesignSystem
import SwiftUI

struct ThreadManagementProfileView: View {
    let memberID: String
    let repository: any ThreadManagementRepository
    @State private var profile: ThreadManagementProfile?
    @State private var failure: String?
    @State private var revision = 0

    var body: some View {
        Group {
            if let profile {
                ScrollView {
                    VStack(alignment: .leading, spacing: UMCSpacing.value16) {
                        HStack(spacing: UMCSpacing.value12) {
                            AsyncImage(url: publicURL(profile.profileImageLink)) { phase in
                                if let image = phase.image {
                                    image.resizable().scaledToFill()
                                } else {
                                    Text(String(profile.name.prefix(1))).umcTypography(.title2Bold)
                                }
                            }
                            .frame(width: 56, height: 56)
                            .background(UMCColor.Semantic.fillNeutralWeak75).clipShape(Circle())
                            VStack(alignment: .leading) {
                                Text([profile.name, profile.nickname].compactMap { $0 }
                                    .joined(separator: " / ")).umcTypography(.title3Bold)
                                if let school = profile.schoolName { Text(school) }
                            }
                        }
                        Divider()
                        Text("활동 이력").umcTypography(.headlineBold)
                        if profile.challengerRecords.isEmpty { Text("활동 이력이 없어요.") }
                        ForEach(profile.challengerRecords.indices, id: \.self) { index in
                            let record = profile.challengerRecords[index]
                            Text([record.gisu.map { $0 + "기" }, record.part].compactMap { $0 }
                                .joined(separator: " · "))
                        }
                        Text("연락처·외부 링크").umcTypography(.headlineBold)
                        linkRow("이메일", nil)
                        linkRow("GitHub", profile.profile?.github)
                        linkRow("LinkedIn", profile.profile?.linkedIn)
                        linkRow("Blog", profile.profile?.blog)
                        linkRow("Instagram", profile.profile?.instagram)
                        linkRow("개인 사이트", profile.profile?.personal)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(minHeight: 240, idealHeight: 440, maxHeight: 500)
            } else if let failure {
                Text(failure).foregroundStyle(UMCColor.Semantic.iconError)
                Button("다시 시도") { revision += 1 }
            } else { ProgressView() }
        }
        .task(id: revision) {
            failure = nil
            do {
                let result = try await repository.profile(memberID: memberID)
                try Task.checkCancellation()
                profile = result
            } catch {
                if !Task.isCancelled { failure = error.localizedDescription }
            }
        }
    }

    private func linkRow(_ title: String, _ value: String?) -> some View {
        LabeledContent(title) {
            if let value, let url = publicURL(value) {
                Link(value, destination: url).lineLimit(1)
            } else if let value, !value.isEmpty {
                Text(value).textSelection(.enabled)
            } else {
                Text("비공개 항목이에요.").foregroundStyle(.secondary)
            }
        }
    }

    private func publicURL(_ value: String?) -> URL? {
        guard let value, let url = URL(string: value), let scheme = url.scheme?.lowercased(),
              ["https", "http"].contains(scheme), url.host != nil else { return nil }
        return url
    }
}
