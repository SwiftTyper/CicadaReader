//
//  ImportButtonStyle.swift
//  Readify
//
//  Created by Wit Owczarek on 10/11/2025.
//

import Foundation
import SwiftUI

struct ImportButtonStyle: ButtonStyle {
    let symbol: String
    
    func makeBody(configuration: Self.Configuration) -> some View {
        VStack(alignment: .center, spacing: 12) {
            Image(systemName: symbol)
                .font(.title2)
                .foregroundStyle(.secondary)
            
            configuration.label
                .frame(maxHeight: .infinity, alignment: .center)
        }
        .multilineTextAlignment(.center)
        .font(.headline)
        .foregroundColor(.primary)
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(minHeight: 50)
        .background(Material.thin)
        .cornerRadius(12)
    }
}

extension ButtonStyle where Self == ImportButtonStyle {
    static func importStyle(symbol: String) -> Self {
        ImportButtonStyle(symbol: symbol)
    }
}
