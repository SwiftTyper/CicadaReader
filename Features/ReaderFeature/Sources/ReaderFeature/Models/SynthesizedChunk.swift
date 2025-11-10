//
//  SynthesizedChunk.swift
//  Readify
//
//  Created by Wit Owczarek on 10/11/2025.
//

import Foundation

struct SynthesizedChunk {
    let content: String
    let audioData: Data
}

public struct Book: Hashable {
    let title: String
    let content: String
    
    public init(title: String = "", content: String) {
        self.title = title
        self.content = content
    }
}
