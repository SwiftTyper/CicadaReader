// The Swift Programming Language
// https://docs.swift.org/swift-book
import SwiftUI

struct LineByLineInBlurOutTransition: Transition {
    var duration: TimeInterval = 0.6
    
    func body(content: Content, phase: TransitionPhase) -> some View {
        let renderer = LineByLineAppearanceTextRenderer(
            progress: phase == .willAppear ? 0.0 : 1.0,
            duration: duration,
            singleLineDurationRatio: 0.9
        )
        
        let animation: Animation = phase == .identity
        ? .linear(duration: duration)
        : .easeOut(duration: duration * 0.6)
        
        content
            .textRenderer(renderer)
            .scaleEffect(phase == .didDisappear ? 0.9 : 1.0)
            .opacity(phase == .didDisappear ? 0.0 : 1.0)
            .blur(radius: phase == .didDisappear ? 2.0 : 0.0)
            .offset(x: 0, y: phase == .didDisappear ? -10.0 : 0.0)
        /**
         Overriding the animation set by the parent component
         to have the timing curve be isolated to this transition.
         This is needed because LineByLine text renderer
         assumes a linear time progression and it calculates
         timing curves itself internally.
         Similar thing with the out-animation, it should always be
         set to ease-in because it looks better for the usecases
         for which this transition is intendede.
         Note: overriding using .transaction() crashes SwiftUI on
         iOS 26.
         */
            .animation(animation, value: phase)
    }
}

struct Bruh: Transition {
    var duration: TimeInterval = 0.6
    
    func body(content: Content, phase: TransitionPhase) -> some View {
        let animation: Animation = phase == .identity
        ? .linear(duration: duration)
        /**
         0.6 to make the out-animation a bit faster
         */
        : .easeOut(duration: duration * 0.6)
        
        content
            .scaleEffect(phase == .didDisappear ? 0.9 : 1.0)
            .opacity(phase == .didDisappear ? 0.0 : 1.0)
            .blur(radius: phase == .didDisappear ? 2.0 : 0.0)
            .offset(x: 0, y: phase == .didDisappear ? -10.0 : 0.0)
            .animation(animation, value: phase)
    }
}
