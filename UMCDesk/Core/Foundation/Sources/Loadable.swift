//
//  Loadable.swift
//  UMCFoundation
//
//  Created by euijjang97 on 10/6/26.
//

import Foundation

/// Inline state for feature loading, validation and recoverable errors.
public enum Loadable<Value> {
    case idle
    case loading
    case loaded(Value)
    case failed(any Error)
}
