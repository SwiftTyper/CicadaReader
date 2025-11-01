//
//  ReaderStatus.swift
//  Readify
//
//  Created by Wit Owczarek on 01/11/2025.
//

import Foundation

enum ReaderStatus {
    case reading
    case idle
    case loading
    case preparing
    
    mutating func toggle() {
        if self == .reading {
            self = .idle
        } else {
            self = .reading
        }
    }
}
