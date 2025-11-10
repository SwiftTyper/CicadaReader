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
    
    var title: String {
        if vm.status == .reading || vm.status == .loading {
            "Pause"
        } else if vm.status == .restartable {
            "Restart"
        } else {
            "Play"
        }
    }
    
    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button {
                vm.skip(.backward)
            } label: {
                Image(systemName: "arrow.uturn.backward")
            }
            .disabled(!vm.canStepBack)
            
            Button {
                vm.skip(.forward)
            } label: {
                Image(systemName: "arrow.uturn.forward")
            }
            .disabled(!vm.canStepForward)
        }
        
        ToolbarItem(placement: .bottomBar) {
            Button {
                vm.toggleAutoRead()
            } label: {
                HStack {
                    Image(systemName: symbolName)
                        .contentTransition(.symbolEffect(.replace))
                    Text(title)
                        .font(.headline.bold())
                }
                .frame(width: 90)
                .transition(.blurReplace)
            }
            .disabled(vm.status == .preparing)
        }
    }
}
