//
//  BaseTargetType.swift
//  UMCNetworkKit
//
//  Created by euijjang97 on 10/6/26.
//

import Foundation
import Moya

/// Feature routers supply their environment instead of reading the app bundle.
public protocol BaseTargetType: TargetType {
    var environment: NetworkEnvironment { get }
}

extension BaseTargetType {
    public var baseURL: URL { environment.baseURL }
    public var headers: [String: String]? { environment.defaultHeaders }
    public var validationType: ValidationType { .successCodes }
}
