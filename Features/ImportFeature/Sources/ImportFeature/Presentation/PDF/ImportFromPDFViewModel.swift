//
//  ImportFromPDFViewModel.swift
//  Readify
//
//  Created by Wit Owczarek on 11/11/2025.
//

import Foundation
import Observation
@preconcurrency import PDFKit

@MainActor
@Observable
class ImportFromPDFViewModel {
    var errorMessage: String? = nil
    var isLoading: Bool = false

    @ObservationIgnored private var currentTask: Task<Void, Never>? = nil
    
    func onResult(_ result: Result<[URL], Error>, action: @escaping (ImportContent) -> Void) {
        self.isLoading = true
        
        switch result {
            case .success(let urls):
                let previousTask = self.currentTask
                previousTask?.cancel()
                
                self.currentTask = Task { [previousTask] in
                    _ = await previousTask?.value
                    await startBookImport(urls: urls, action: action)
                }
                
            case .failure(let error):
                self.errorMessage = error.localizedDescription
        }
    }
    
    private func startBookImport(urls: [URL], action: @escaping (ImportContent) -> Void) async {
        guard let url = urls.first else {
            self.errorMessage = "No PDF file found."
            self.isLoading = false
            return
        }
        
        guard url.startAccessingSecurityScopedResource() else {
            self.errorMessage = "Failed to access PDF file"
            self.isLoading = false
            return
        }
        
        guard let book = await getBook(from: url) else {
            self.errorMessage = "Failed while parsing the PDF."
            self.isLoading = false
            return
        }
        
        self.isLoading = false
        action(book)
    }
    
    private func getBook(from url: URL) async -> ImportContent? {
        guard let document = PDFDocument(url: url) else { return nil }
        
        url.stopAccessingSecurityScopedResource()
        
        let title = document.documentAttributes?[PDFDocumentAttribute.titleAttribute] as? String
        ?? url.deletingPathExtension().lastPathComponent
        
        let pageCount = document.pageCount
        
        let fullText = await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var result = ""
                for i in 0..<pageCount {
                    guard Task.isCancelled == false else { return }
                    if let text = document.page(at: i)?.string {
                        result += text + "\n\n"
                    }
                }
                result = result.trimmingCharacters(in: .whitespacesAndNewlines)
                continuation.resume(returning: result)
            }
        }
        
        let trimmed = fullText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return ImportContent(title: title, content: trimmed)
    }
}
