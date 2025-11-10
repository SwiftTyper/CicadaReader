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
        try Task.checkCancellation()
        
        if buffer.isEmpty {
            let item = try await produce()
            buffer.append(item)
        }
        
        let item = buffer.removeFirst()
        startBackgroundRefill()
        return item
    }

    private func startBackgroundRefill() {
        fillTask?.cancel()
        fillTask = nil

        guard buffer.count < targetSize else { return }

        fillTask = Task {
//            while buffer.count < targetSize && !Task.isCancelled {
            guard Task.isCancelled == false else { return }
            guard let newItem = try? await self.produce() else { return }
            append(newItem)
//            }
        }
    }

    private func append(_ item: T) {
        buffer.append(item)
    }

    func reset() {
        fillTask?.cancel()
        fillTask = nil
        buffer.removeAll()
    }
}
