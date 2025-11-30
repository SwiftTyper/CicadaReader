import Foundation
import SwiftUI
import TTSFeature

public struct ReaderView<Reader: View>: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    @State private var vm: ReaderViewModel
    private let content: ReaderContent
    private let reader: (Int, String, @escaping () async -> String) -> Reader
 
    public init(
        content: ReaderContent,
        synthesizer: TtSManager,
        @ViewBuilder reader: @escaping (Int, String, @escaping () async -> String) -> Reader,
    ) {
        self.content = content
        self.reader = reader
        self._vm = State(
            wrappedValue: ReaderViewModel(
                synthesizer: synthesizer,
                contentUrl: content.url
            )
        )
    }
    
    private var alertIsPresented: Binding<Bool> {
        Binding {
            vm.errorMessage != nil
        } set: { value in
            guard value == false else { return }
            vm.errorMessage = nil
        }
    }
    
    public var body: some View {
        NavigationStack {
            reader(vm.currentWordIndex, vm.text, vm.onScrollChange)
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
                    message: { Text(vm.errorMessage ?? "Please contact support") }
                )
                .loader(
                    self.vm.status == .loading || self.vm.status == .preparing,
                    isFullScreen: self.vm.status == .preparing,
                    label: vm.status == .preparing ? "Preparing..." : "Loading..."
                )
                .task { await self.vm.setup() }
                .onDisappear() { self.vm.cancel() }
        }
    }
}
