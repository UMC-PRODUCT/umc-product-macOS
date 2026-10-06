//
//  SessionResetting.swift
//  UMCNetworkKit
//
//  Created by euijjang97 on 10/6/26.
//

/// App-owned cleanup invoked after tokens have been cleared.
public protocol SessionResetting: Sendable {
    func resetSession() async
}
