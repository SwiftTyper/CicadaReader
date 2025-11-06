//
//  ReaderBottomBarView.swift
//  Readify
//
//  Created by Wit Owczarek on 21/10/2025.
//

import Foundation
import SwiftUI

struct ReaderViewToolbar: ToolbarContent {
    let vm: ReaderViewModel
    
    var symbolName: String {
        if vm.status == .reading || vm.status == .loading {
            "pause.fill"
        } else if vm.status == .restartable {
            "arrow.counterclockwise"
        } else {
            "play.fill"
        }
    }
    
    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button {
                vm.stepBack()
            } label: {
                Image(systemName: "arrow.uturn.backward")
            }
            .disabled(!vm.canStepBack)
            
            Button {
                vm.stepForward()
            } label: {
                Image(systemName: "arrow.uturn.forward")
            }
            .disabled(!vm.canStepForward)
        }
        
        ToolbarItem(placement: .bottomBar) {
            Button {
                vm.toggleAutoRead()
            } label: {
                Image(systemName: symbolName)
            }
            .contentTransition(.symbolEffect(.replace))
            .disabled(vm.status == .preparing)
        }
    }
}
