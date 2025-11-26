//
//  File.swift
//  OnboardingFeature
//
//  Created by Wit Owczarek on 25/11/2025.
//

import Foundation
import SwiftUI

public struct OnboardingView: View {
    @State private var currentStepIndex: Int? = nil
    
    private let steps: [OnboardingStep]
    private let onComplete: () -> Void
    
    public init(
        _ steps: [OnboardingStep],
        onComplete: @escaping () -> Void
    ) {
        self.steps = steps
        self.onComplete = onComplete
    }
    
    public var body: some View {
        ZStack {
            if let index = currentStepIndex {
                OnboardingStepView(step: steps[index])
            }
            
            VStack {
                Spacer()
                Text("Tap to Continue")
                    .foregroundStyle(.secondary)
                    .font(.headline)
                    .padding()
            }
        }
        .contentShape(.rect)
        .onTapGesture { next() }
        .padding(.horizontal, 42)
        .onAppear { currentStepIndex = 0 }
        .transition(.blurReplace)
    }
    
    private func next() {
        if let index = currentStepIndex, index == steps.count - 1 {
            withAnimation(.smooth(duration: 1)){
                onComplete()
            }
        } else {
            withAnimation(.smooth(duration: 5)) {
                currentStepIndex = (currentStepIndex ?? 0) + 1
            }
        }
    }
}

#Preview {
    NavigationStack {
        OnboardingView(
            [
                .init("First step of the ondboarding 👋 will wierd animation happen here?",) { didAppear in
                    Image(systemName: didAppear ? "lock.fill" : "lock")
                        .bold()
                },
                .init("Second step of the onboarding ✨") { _ in
                    Image(systemName: "capsule")
                },
                .init("Third step of the onboarding 🎉") { _ in
                    Image(systemName: "person")
                },
            ],
            onComplete: {
                
            }
        )
    }
}
