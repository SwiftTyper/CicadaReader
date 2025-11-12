import Foundation

public struct Book: Hashable, Sendable {
    let title: String
    let content: String
    
    init(
        title: String = "Untitled",
        content: String
    ) {
        self.title = title
        self.content = content
    }
}
