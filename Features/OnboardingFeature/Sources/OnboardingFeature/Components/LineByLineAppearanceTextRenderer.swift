//
//  File.swift
//  OnboardingFeature
//
//  Created by Wit Owczarek on 25/11/2025.
//

import Foundation
import SwiftUI

struct LineByLineAppearanceTextRenderer: TextRenderer, Animatable {
    var progress: Double
    let duration: TimeInterval
    let singleLineDurationRatio: Double
    
    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }
    
    func draw(layout: Text.Layout, in context: inout GraphicsContext) {
        let lineDelayRatio = (1.0 - singleLineDurationRatio) / Double(layout.count)
        let lineDuration = duration * singleLineDurationRatio
        
        for (lineIndex, line) in layout.enumerated() {
            var lineContext = context
            
            let lineMinProgress = lineDelayRatio * Double(lineIndex)
            let lineProgress = max(min((progress - lineMinProgress) / singleLineDurationRatio, 1.0), 0.0)
            
            let spring = Spring.snappy(duration: lineDuration, extraBounce: 0.2)
            
            let yTranslation = spring.value(
                fromValue: line.typographicBounds.rect.height,
                toValue: 0,
                initialVelocity: 0,
                time: lineDuration * lineProgress
            )
            let opacity = UnitCurve.easeInOut.value(at: lineProgress)
            let blurRadius = 2 * (1.0 - UnitCurve.easeInOut.value(at: lineProgress))
            
            lineContext.translateBy(x: 0, y: yTranslation)
            lineContext.opacity = opacity
            lineContext.addFilter(.blur(radius: blurRadius))
            
            lineContext.draw(line, options: .disablesSubpixelQuantization)
        }
    }
}
