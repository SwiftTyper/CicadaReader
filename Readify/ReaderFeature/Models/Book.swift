//
//  BookModel.swift
//  Readify
//
//  Created by Wit Owczarek on 24/10/2025.
//

import Foundation

struct Book: Codable, Hashable {
    let title: String = "Untitled"
    let content: String
}
