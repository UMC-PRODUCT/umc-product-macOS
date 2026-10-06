//
//  APIConfig.swift
//  UMCFoundation
//
//  Created by euijjang97 on 10/6/26.
//

import Foundation

public enum APIConfig {
    /// Reads app-owned configuration. The shared package never reads Bundle.main.
    public static func baseURL(bundle: Bundle = .main) throws -> URL {
        guard let value = bundle.object(forInfoDictionaryKey: "BASE_URL") as? String,
              let url = URL(string: value),
              url.scheme == "https",
              url.host != nil else {
            throw ConfigurationError.invalidBaseURL
        }
        return url
    }
}

public enum ConfigurationError: Error {
    case invalidBaseURL
}
