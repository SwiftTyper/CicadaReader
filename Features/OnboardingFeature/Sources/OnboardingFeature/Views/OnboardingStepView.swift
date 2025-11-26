//
//  File.swift
//  OnboardingFeature
//
//  Created by Wit Owczarek on 26/11/2025.
//

import Foundation
import SwiftUI

struct OnboardingStepView: View {
    let step: OnboardingStep
    
    var body: some View {
        VStack {
            OnboardingStepContentView(step: step)
                .transition(.blurReplace.animation(.linear(duration: 0.5)))
                .id(step.id)
            
            Text(step.text)
                .font(.system(size: 32, weight: .heavy))
                .transition(LineByLineInBlurOutTransition())
                .id(step.id)
        }
        .frame(maxWidth: .infinity)
    }
}
