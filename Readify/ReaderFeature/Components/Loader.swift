//
//  Loader.swift
//  Readify
//
//  Created by Wit Owczarek on 01/11/2025.
//

import Foundation
import SwiftUI

struct LoaderView: ViewModifier {
    let isActive: Bool
    let isFullScreen: Bool
    let label: String
    
    func body(content: Content) -> some View {
        if isActive && isFullScreen {
            ProgressView(label)
        } else if isActive {
            content
                .overlay {
                   ProgressView(label)
                }
        } else {
            content
        }
    }
}

extension View {
    func loader(_ isActive: Bool, isFullScreen: Bool = false, label: String = "Loading...") -> some View {
        self.modifier(
            LoaderView(
                isActive: isActive,
                isFullScreen: isFullScreen,
                label: label
            )
        )
    }
}
