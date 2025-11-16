//
//  File.swift
//  ReaderFeature
//
//  Created by Wit Owczarek on 16/11/2025.
//

import Foundation

public struct ReaderContent: Hashable {
    public init(title: String?, url: URL) {
        self.title = title ?? "Untitled"
        self.url = url
    }
    
    let title: String
    let url: URL
}
