//
//  PasteImportView.swift
//  Readify
//
//  Created by Wit Owczarek on 20/10/2025.
//

import Foundation
import SwiftUI

struct PasteImportView: View {
    @State private var showError: Bool = false

    let action: (String) -> ()

    var body: some View {
        Button {
            if let text = UIPasteboard.general.string, !text.isEmpty {
                action(text)
            } else {
                showError = true
            }
        } label: {
            Text("Paste from clipboard")
        }
        .buttonStyle(.bordered)
        .alert("Nothing to paste", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        }
    }
}
