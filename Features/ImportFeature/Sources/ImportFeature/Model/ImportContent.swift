import Foundation

struct ImportContent: Hashable, Sendable, Content {
    let title: String?
    let url: URL
}
