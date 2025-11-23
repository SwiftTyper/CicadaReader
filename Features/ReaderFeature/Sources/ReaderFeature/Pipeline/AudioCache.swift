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
    
    // Include all synthesis-affecting parameters here.
    public init(text: String, voice: String?, rate: Double?, pitch: Double?, format: String) {
        // Normalize inputs and build a deterministic string
        let voicePart = voice ?? "defaultVoice"
        let ratePart = String(format: "%.3f", rate ?? 1.0)
        let pitchPart = String(format: "%.3f", pitch ?? 0.0)
        let input = [
            "v=\(voicePart)",
            "r=\(ratePart)",
            "p=\(pitchPart)",
            "fmt=\(format)",
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
    
    public func urlIfExists(for key: AudioCacheKey) -> URL? {
        if let url = memoryIndex[key] { return url }
        // We don’t know extension from key; scan for common audio extensions or a metadata sidecar.
        // To keep it simple, assume m4a as default.
        let candidates = ["m4a", "caf", "wav", "mp3"].map {
            baseURL.appendingPathComponent("\(key.value).\($0)")
        }
        if let found = candidates.first(where: { FileManager.default.fileExists(atPath: $0.path) }) {
            memoryIndex[key] = found
            return found
        }
        return nil
    }
    
    @discardableResult
    public func store(data: Data, for key: AudioCacheKey, fileExtension: String) throws -> URL {
        let url = baseURL.appendingPathComponent("\(key.value).\(fileExtension)")
        try data.write(to: url, options: .atomic)
        memoryIndex[key] = url
        return url
    }
    
    public func remove(for key: AudioCacheKey) throws {
        let candidates = ["m4a", "caf", "wav", "mp3"].map {
            baseURL.appendingPathComponent("\(key.value).\($0)")
        }
        for url in candidates where FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
        memoryIndex[key] = nil
    }
    
    public func clearAll() throws {
        let contents = try FileManager.default.contentsOfDirectory(at: baseURL, includingPropertiesForKeys: nil)
        for url in contents {
            try? FileManager.default.removeItem(at: url)
        }
        memoryIndex.removeAll()
    }
}
