//
//  File.swift
//  ReaderFeature
//
//  Created by Wit Owczarek on 22/11/2025.
//

import Foundation
import CryptoKit

public struct AudioCacheKey: Hashable, Sendable {
    public let value: String
    
    public init(text: String, rate: Double?) {
        let ratePart = String(format: "%.3f", rate ?? 1.0)
        let input = [
            "r=\(ratePart)",
            "text=\(text)"
        ].joined(separator: "|")
        
        let digest = SHA256.hash(data: Data(input.utf8))
        self.value = digest.map { String(format: "%02x", $0) }.joined()
    }
}

public actor AudioSynthesisCache {
    private let baseURL: URL
    private var memoryIndex: [AudioCacheKey: URL] = [:]
    
    public init(subdirectory: String = "AudioSynthesisCache") {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let dir = caches.appendingPathComponent(subdirectory, isDirectory: true)
        self.baseURL = dir
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    }
    
    public func retrieveData(for key: AudioCacheKey) -> Data? {
        guard let url = memoryIndex[key] else { return nil }
        guard let data = try? Data(contentsOf: url) else { return nil }
        return data
    }
    
    public func store(data: Data, for key: AudioCacheKey) throws {
        let url = baseURL.appendingPathComponent("\(key.value).wav")
        try data.write(to: url, options: .atomic)
        memoryIndex[key] = url
    }
    
    public func remove(for key: AudioCacheKey) throws {
        guard let url = memoryIndex[key] else { return }
        try FileManager.default.removeItem(at: url)
        memoryIndex[key] = nil
    }
}
