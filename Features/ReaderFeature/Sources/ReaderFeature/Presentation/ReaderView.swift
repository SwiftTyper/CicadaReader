import Foundation
import SwiftUI
import TTSFeature

public struct ReaderView: View {
    @State private var vm: ReaderViewModel
    
    private let content: ReaderContent
    
    private var alertIsPresented: Binding<Bool> {
        Binding {
            vm.errorMessage != nil
        } set: { value in
            guard value == false else { return }
            vm.errorMessage = nil
        }
    }
    
    public init(
        content: ReaderContent,
        synthesizer: TtSManager,
    ) {
        self.content = content
        self._vm = State(
            wrappedValue: ReaderViewModel(
                synthesizer: synthesizer,
                contentUrl: content.url
            )
        )
    }

    public var body: some View {
        NavigationStack {
            LazyScrollableTextView(
               text: vm.text,
               wordIndex: vm.currentWordIndex,
               loadMoreCallback: {
                   Task { await self.vm.onScrollChange() }
               }
           )
            .navigationTitle(content.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ReaderViewToolbar(vm: vm) }
            .alert(
                "Something went wrong!",
                isPresented: alertIsPresented,
                actions: {},
                message: { Text(vm.errorMessage ?? "Please contact support")}
            )
            .loader(
                self.vm.status == .loading || self.vm.status == .preparing,
                isFullScreen: self.vm.status == .preparing
            )
            .task { await self.vm.setup() }
            .onDisappear() { self.vm.cancel() }
        }
    }
}
