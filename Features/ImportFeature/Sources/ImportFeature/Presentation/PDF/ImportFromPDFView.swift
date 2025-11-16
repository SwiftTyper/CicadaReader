//
//  ImportFromPDFView.swift
//  Readify
//
//  Created by Wit Owczarek on 10/11/2025.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct ImportFromPDFView: View {
    @State private var isFilePickerShown: Bool = false
    @State private var vm: ImportFromPDFViewModel = .init()
    
    let action: (ImportContent) -> Void
    
    var body: some View {
        Button {
            self.isFilePickerShown = true
        } label: {
            Text("Upload a .PDF File")
        }
        .overlay {
            if self.vm.isLoading { ProgressView() }
        }
        .alert(
            "File Import Failed",
            isPresented: .constant(self.vm.errorMessage != nil),
            actions: {},
            message: { Text(self.vm.errorMessage ?? "") }
        )
        .fileImporter(
            isPresented: self.$isFilePickerShown,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: false
        ) {
            self.vm.onResult($0, action: self.action)
        }
    }
}
