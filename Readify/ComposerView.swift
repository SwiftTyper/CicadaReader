//
//  ContentView.swift
//  Readify
//
//  Created by Wit Owczarek on 19/10/2025.
//

import SwiftUI
import TTSFeature
import TextFeature
import ReaderFeature
import ImportFeature
import OnboardingFeature

struct ComposerView: View {
    @State private var content: ReaderContent? = nil
    
    private var steps: [OnboardingStep] {
        [
            OnboardingStep(
                "Listen to any text or file."
            ) { didAppear in
                Image(systemName: "waveform")
                    .symbolEffect(.drawOn, isActive: !didAppear)
                    .font(.extraLargeTitle)
                    .foregroundStyle(.pink)
                    .padding(8)
            },
            OnboardingStep(
                "Natural-sounding AI voices."
            ) { didAppear in
                Image(systemName: "person.2.wave.2.fill")
                    .symbolEffect(.variableColor, value: didAppear)
                    .font(.extraLargeTitle)
                    .padding(8)
                
            },
            OnboardingStep(
                "No Censorship"
            ){ _ in
            },
            OnboardingStep(
                "Everything stays private on your device."
            ) { didAppear in
                Image(systemName: didAppear ? "lock.fill" : "lock.open.fill")
                    .frame(maxWidth: .infinity)
                    .font(.extraLargeTitle)
                    .foregroundStyle(.blue)
                    .padding(8)
                    .contentTransition(.symbolEffect(.replace))
            }
        ]
    }
    
    private var infoMessage: some View {
        HStack(spacing: 10) {
            Image(systemName: "info.circle")
                .foregroundStyle(.blue)
                .font(.body)

            Text("Currently supports only English")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding()
        .background(.blue.opacity(0.08))
        .cornerRadius(14)
        .padding(.horizontal)
        .padding(.top, 12)
    }

    var body: some View {
        OnboardingView(steps) {
            NavigationStack {
                ScrollView {
                    ImportView { content in
                        self.content = ReaderContent(
                            title: content.title,
                            url: content.url
                        )
                    }
                    .padding(.horizontal)
                    
                    infoMessage
                }
                .scrollBounceBehavior(.basedOnSize)
                .navigationTitle("Readify")
                .toolbarTitleDisplayMode(.inlineLarge)
                .navigationDestination(item: self.$content) { book in
                    ReaderView(
                        content: book,
                        synthesizer: .init(),
                    ) { wordIndex, text, loadMore in
                        LazyTextView(
                            currentWordIndex: wordIndex,
                            initialText: text,
                            loadMore: { await loadMore() }
                        )
                    }
                }
            }
        }
    }
}

private extension Font {
    static let extraLargeTitle = Font.system(size: 56)
}

#Preview {
    ComposerView()
}
