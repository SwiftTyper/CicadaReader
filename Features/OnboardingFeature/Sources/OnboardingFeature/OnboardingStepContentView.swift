//
//  File.swift
//  OnboardingFeature
//
//  Created by Wit Owczarek on 26/11/2025.
//

import Foundation
import SwiftUI

struct OnboardingStepContentView: View {
    let step: OnboardingStep
    
    @State private var shouldAnimate: Bool = false
    
    var body: some View {
        step.content(self.shouldAnimate)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.shouldAnimate = true
                }
            }
    }
}
