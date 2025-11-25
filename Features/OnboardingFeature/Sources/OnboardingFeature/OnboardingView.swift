//
//  File.swift
//  OnboardingFeature
//
//  Created by Wit Owczarek on 25/11/2025.
//

import Foundation
import SwiftUI

public struct TextAppearanceView: View {
    @State private var currentStepIndex: Int? = nil
    
    private let steps: [Step]
    private let onComplete: () -> Void
    
    public init(
        steps: [Step],
        onComplete: @escaping () -> Void
    ) {
        self.steps = steps
        self.onComplete = onComplete
    }
    
    public var body: some View {
        ZStack {
            if let currentStepIndex {
                let step = steps[currentStepIndex]
                
                Text(step.text)
                    .id(step.id)
                    .transition(
                        LineByLineInBlurOutTransition()
                    )
                    .font(.system(size: 32, weight: .heavy))
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
        .onTapGesture { self.next() }
        .padding(.horizontal, 42)
        .onAppear { self.currentStepIndex = 0 }
    }
    
    func next() {
        withAnimation(.smooth(duration: 5)) {
            if currentStepIndex == steps.count - 1 {
                
            } else {
                currentStepIndex = currentStepIndex.map {
                    ($0 + 1) % steps.count
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        TextAppearanceView(
            steps: [
                .init(text: "First step of the onboarding 👋"),
                .init(text: "Second step of the onboarding ✨"),
                .init(text: "Third step of the onboarding 🎉"),
            ],
            onComplete: {}
        )
    }
}
