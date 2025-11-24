//
//  File.swift
//  ReaderFeature
//
//  Created by Wit Owczarek on 23/11/2025.
//

import Foundation
import SwiftUI

extension WrappingHStack {
    @inline(__always)
    static func getWidth<V: View>(of view: V) -> Double {
        let hostingController = UIHostingController(rootView: view)
        let container = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        return hostingController.sizeThatFits(in: container).width
    }
}

extension InternalWrappingHStack {
    @inline(__always)
    static func getWidth<V: View>(of view: V) -> Double {
        let hostingController = UIHostingController(rootView: view)
        let container = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        return hostingController.sizeThatFits(in: container).width
    }
}

