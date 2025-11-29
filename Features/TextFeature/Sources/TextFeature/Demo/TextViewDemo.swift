import UIKit
import SwiftUI

fileprivate let longTextExample =  "/*Lorem*/ ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua..."
fileprivate let initial = Array(repeating: longTextExample, count: 30).reduce("", +)

struct TextViewDemo: View {
    @State private var scrollToWordIndex: Int? = nil

    var body: some View {
        NavigationStack {
            LazyTextView(
                currentWordIndex: scrollToWordIndex,
                initialText: initial,
                loadMore: fetchMoreTextExample
            )
            .toolbar {
                Button("Next"){
                    self.scrollToWordIndex = (scrollToWordIndex ?? 0) + 50
                }
            }
        }
    }
    
    private func fetchMoreTextExample() async -> String {
        return Array(repeating: longTextExample, count: 100).reduce("", +)
    }
}


#Preview {
    TextViewDemo()
}
