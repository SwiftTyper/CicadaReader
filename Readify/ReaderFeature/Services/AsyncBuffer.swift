//
//  AsyncBuffer.swift
//  Readify
//
//  Created by Wit Owczarek on 01/11/2025.
//

import Foundation

actor AsyncBuffer<T> {
    private var buffer: [T] = []
    private var fillTask: Task<Void, Never>? = nil
    private let produce: @Sendable () async throws -> T
    private let targetSize: Int

    init(targetSize: Int = 2, produce: @escaping @Sendable () async throws -> T) {
        self.targetSize = targetSize
        self.produce = produce
    }

    func next() async throws -> T {
        if buffer.isEmpty {
            let item = try await produce()
            append(item)
        }

        let item = buffer.removeFirst()
        
        startBackgroundRefill()
        
        return item
    }

    private func startBackgroundRefill() {
//        guard fillTask == nil || fillTask?.isCancelled == true else { return }
        
        guard buffer.count < targetSize else { return }
//        let needed = targetSize - buffer.count
        
        fillTask = Task {
//            try? await withThrowingTaskGroup(of: T.self) { group in
//                for _ in 0..<needed {
//                    group.addTask {
            guard let produce = try? await self.produce() else { return }
            self.append(produce)
            //sth might be wrong here
                    
//                    }
//                }
//
//                for try await newItem in group {
//                    self.append(newItem)
//                }
//            }
        }
        
        if Task.isCancelled {
            cancel()
        }
    }

    private func append(_ item: T) {
        buffer.append(item)
    }

    func cancel() {
        fillTask?.cancel()
        fillTask = nil
    }
    
    func reset() {
        //to check if fillTask is needed
        fillTask?.cancel()
        fillTask = nil
        buffer = []
    }
}
