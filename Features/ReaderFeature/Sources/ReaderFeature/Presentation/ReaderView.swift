import Foundation
import SwiftUI
import TTSFeature
import TextFeature

public struct ReaderView: View {
    @State private var vm: ReaderViewModel
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
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
            LazyTextView(
                currentWordIndex: vm.currentWordIndex,
                initialText: vm.text,
                loadMore: { await self.vm.onScrollChange() }
            )
            .ignoresSafeArea(.all, edges: .bottom)
            .padding(.horizontal, verticalSizeClass == .compact ? 0 : 16)
            .navigationTitle(content.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ReaderViewToolbar(vm: vm) }
            .toolbarBackground(.regularMaterial)
            .toolbarVisibility(.automatic, for: .navigationBar)
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
