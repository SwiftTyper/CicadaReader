//
//  File.swift
//  OnboardingFeature
//
//  Created by Wit Owczarek on 25/11/2025.
//

import Foundation
import SwiftUI

public struct OnboardingStep: Identifiable {
    public let id = UUID()
    public let text: String
    public let content: (Bool) -> AnyView
    
    public init<Content: View>(
         _ text: String,
         @ViewBuilder content: @escaping (Bool) -> Content
     ) {
         self.text = text
         self.content = { flag in
             AnyView(content(flag))
         }
     }
}
