//
//  File.swift
//  OnboardingFeature
//
//  Created by Wit Owczarek on 25/11/2025.
//

import Foundation
import SwiftUI

public struct OnboardingView<Home: View>: View {
    @State private var currentStepIndex: Int? = nil
    @State private var didShowOnboarding: Bool
    
    @ViewBuilder var home: () -> Home
    
    private let steps: [OnboardingStep]
    private let didShowOnboardingKey: String = "didShowOnboardingKey"
    
    public init(
        _ steps: [OnboardingStep],
        @ViewBuilder home: @escaping () -> Home,
    ) {
        self.steps = steps
        self.home = home
        self.didShowOnboarding = UserDefaults.standard.bool(forKey: didShowOnboardingKey)
    }
    
    public var body: some View {
        if !didShowOnboarding {
            ZStack {
                if let index = currentStepIndex {
                    OnboardingStepView(step: steps[index])
                }
                
                Text("Tap to Continue")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .padding()
            }
            .contentShape(.rect)
            .onTapGesture { next() }
            .padding(.horizontal, 42)
            .onAppear { currentStepIndex = 0 }
            .transition(.blurReplace)
        } else {
            home()
        }
    }
    
    private func next() {
        if let index = currentStepIndex, index == steps.count - 1 {
            withAnimation(.smooth(duration: 1)){
                didShowOnboarding = true
            }
            UserDefaults.standard.set(true, forKey: didShowOnboardingKey)
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
                .init("First step of the ondboarding") { didAppear in
                    Image(systemName: didAppear ? "lock.fill" : "lock")
                        .bold()
                },
                .init("Second step of the onboarding ✨") { _ in
                    Image(systemName: "capsule")
                },
                .init("Third step of the onboarding 🎉") { _ in
                    Image(systemName: "person")
                },
            ]
        ) {
            Text("Home")
        }
    }
}
