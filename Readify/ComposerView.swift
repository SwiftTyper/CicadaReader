//
//  ContentView.swift
//  Readify
//
//  Created by Wit Owczarek on 19/10/2025.
//

import SwiftUI
import TTSFeature
import ReaderFeature
import ImportFeature
import OnboardingFeature

struct ComposerView: View {
    @State private var content: ReaderContent? = nil
    @State private var didShowOnboarding: Bool = false
    //    @AppStorage("didShowOnboarding") private var didShowOnboarding: Bool = false

    var body: some View {
        if didShowOnboarding {
            NavigationStack {
                ScrollView {
                    ImportView { content in
                        self.content = ReaderContent(
                            title: content.title,
                            url: content.url
                        )
                    }
                    .padding(.horizontal)
                }
                .navigationTitle("Readify")
                .toolbarTitleDisplayMode(.inlineLarge)
                .navigationDestination(item: self.$content) { book in
                    ReaderView(
                        content: book,
                        synthesizer: .init()
                    )
                }
            }
        } else {
            OnboardingView(
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
            ) {
                self.didShowOnboarding = true
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
