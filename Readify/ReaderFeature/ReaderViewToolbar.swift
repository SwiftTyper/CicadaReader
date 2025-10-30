//
//  ReaderBottomBarView.swift
//  Readify
//
//  Created by Wit Owczarek on 21/10/2025.
//

import Foundation
import SwiftUI

struct ReaderViewToolbar: ToolbarContent {
    let model: ReaderViewModel
    let controller: ReaderController
    
    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button {
                model.stepBack()
            } label: {
                Image(systemName: "arrow.uturn.backward")
            }
            .disabled(!model.canStepBack)
            
            Button {
                model.stepForward()
            } label: {
                Image(systemName: "arrow.uturn.forward")
            }
            .disabled(!model.canStepForward)
        }
        
        ToolbarItem(placement: .bottomBar) {
            Button {
                Task {
                    await controller.read()
                }
//                model.toggleAutoRead()
            } label: {
                Image(systemName: model.status == .reading ? "pause.fill" : "play.fill")
            }
            .contentTransition(.symbolEffect(.replace))
        }
    }
}
