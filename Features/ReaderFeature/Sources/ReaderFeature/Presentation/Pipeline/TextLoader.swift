//
//  File.swift
//  ReaderFeature
//
//  Created by Wit Owczarek on 16/11/2025.
//

import Foundation

actor TextLoader {
    private let url: URL
    private let chunkSize = 4096
    private var offset: Int = 0
    
    var chunker: TextChunker
    
    init(url: URL, chunker: TextChunker) {
        self.url = url
        self.chunker = chunker
    }
    
    func nextChunk() async throws -> String {
        let text = try readChunk(offset: offset)
        offset += chunkSize
        await chunker.compute(newText: text)
        return text
    }
    
    private func readChunk(offset: Int) throws -> String {
        let handle = try FileHandle(forReadingFrom: url)
        do {
            try handle.seek(toOffset: UInt64(offset))
        } catch {
            throw ChunkingError.runOutOfChunks
        }
        let data = try handle.read(upToCount: chunkSize) ?? Data()
        try handle.close()
        return String(decoding: data, as: UTF8.self)
    }
}
