//
//  ImportView.swift
//  Readify
//
//  Created by Wit Owczarek on 20/10/2025.
//

import Foundation
import SwiftUI

public struct ImportView: View {
    private let onImport: (Content) -> Void
    
    public init(onImport: @escaping (Content) -> Void) {
        self.onImport = onImport
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Import Content")
                .font(.title2.bold())
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text("Supports uploading PDF files or pasting content from the clipboard to extract text.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            HStack {
                PasteFromClipboardView { fileUrl in
                    self.onImport(ImportContent(title: nil, url: fileUrl))
                }
                .buttonStyle(.importStyle(symbol: "list.clipboard.fill"))
                
                ImportFromPDFView { file in
                    self.onImport(file)
                }
                .buttonStyle(.importStyle(symbol: "text.document.fill"))
            }
            .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    ImportView() { _ in
        
    }
    .padding()
}

