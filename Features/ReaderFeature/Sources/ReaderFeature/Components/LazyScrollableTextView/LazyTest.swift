//
//  File.swift
//  ReaderFeature
//
//  Created by Wit Owczarek on 23/11/2025.
//

import Foundation
import SwiftUI

/// This class manages content and the calculation of their widths (reusing it).
/// It should be reused whenever possible.
class ContentManager {
    let items: [ViewType]
    let getWidths: () -> [Double]
    
    lazy var widths: [Double] = {
        getWidths()
    }()

    init(items: [ViewType], getWidths: @escaping () -> [Double]) {
        self.items = items
        self.getWidths = getWidths
    }
    
    func isVisible(viewIndex: Int) -> Bool {
        widths[viewIndex] > 0
    }
   
}

/// This View draws the WrappingHStack content taking into account the passed width, alignment and spacings.
/// Note that the passed LineManager and ContentManager should be reused whenever possible.
struct InternalWrappingHStack: View {
    let width: CGFloat
    let alignment: HorizontalAlignment
    let spacing: WrappingHStack.Spacing
    let lineSpacing: CGFloat
    let firstItemOfEachLine: [Int]
    let contentManager: ContentManager
    let scrollToElement: Int
    let proxy: ScrollViewProxy

    init(
        width: CGFloat,
        alignment: HorizontalAlignment,
        spacing: WrappingHStack.Spacing,
        lineSpacing: CGFloat,
        contentManager: ContentManager,
        scrollToElement: Int,
        proxy: ScrollViewProxy
    ) {
        self.width = width
        self.alignment = alignment
        self.spacing = spacing
        self.lineSpacing = lineSpacing
        self.contentManager = contentManager
        self.firstItemOfEachLine = {
            var firstOfEach = [Int]()
            var currentWidth: Double = width
            for (index, element) in contentManager.items.enumerated() {
                switch element {
                case .newLine:
                    firstOfEach += [index]
                    currentWidth = width
                case .any where contentManager.isVisible(viewIndex: index):
                    let itemWidth = contentManager.widths[index]
                    if currentWidth + itemWidth + spacing.minSpacing > width {
                        currentWidth = itemWidth
                        firstOfEach.append(index)
                    } else {
                        currentWidth += itemWidth + spacing.minSpacing
                    }
                default:
                    break
                }
            }

            return firstOfEach
        }()
        self.scrollToElement = scrollToElement
        self.proxy = proxy
    }
    
    
    func rowIndex(viewIndex: Int) -> Int {
        return max((firstItemOfEachLine.firstIndex(where: { $0 > viewIndex }) ?? 0) - 1 , 0)
    }
    
    func shouldHaveSideSpacers(line i: Int) -> Bool {
        if case .constant = spacing {
            return true
        }
        if case .dynamic = spacing, hasExactlyOneElement(line: i) {
            return true
        }
        return false
    }

    var totalLines: Int {
        firstItemOfEachLine.count
    }

    func startOf(line i: Int) -> Int {
        firstItemOfEachLine[i]
    }

    func endOf(line i: Int) -> Int {
        i == totalLines - 1 ? contentManager.items.count - 1 : firstItemOfEachLine[i + 1] - 1
    }

    func hasExactlyOneElement(line i: Int) -> Bool {
        startOf(line: i) == endOf(line: i)
    }
    
    var body: some View {
        LazyVStack(alignment: alignment, spacing: lineSpacing) {
            ForEach(0 ..< totalLines, id: \.self) { lineIndex in
                HStack(spacing: 0) {
                    if alignment == .center || alignment == .trailing, shouldHaveSideSpacers(line: lineIndex) {
                        Spacer(minLength: 0)
                    }
                    
                    ForEach(startOf(line: lineIndex) ... endOf(line: lineIndex), id: \.self) {
                        if case .dynamicIncludingBorders = spacing,
                            startOf(line: lineIndex) == $0
                        {
                            Spacer(minLength: spacing.minSpacing)
                        }
                        
                        if case .any(let anyView) = contentManager.items[$0], contentManager.isVisible(viewIndex: $0) {
                            anyView
                        }
                        
                        if endOf(line: lineIndex) != $0 {
                            if case .any = contentManager.items[$0], !contentManager.isVisible(viewIndex: $0) { } else {
                                if case .constant(let exactSpacing) = spacing {
                                    Spacer(minLength: 0)
                                        .frame(width: exactSpacing)
                                } else {
                                    Spacer(minLength: spacing.minSpacing)
                                }
                            }
                        } else if case .dynamicIncludingBorders = spacing {
                            Spacer(minLength: spacing.minSpacing)
                        }
                    }
                    
                    if alignment == .center || alignment == .leading, shouldHaveSideSpacers(line: lineIndex) {
                        Spacer(minLength: 0)
                    }
                }
                .frame(maxWidth: .infinity)
                .id(lineIndex)
            }
        }
        .onChange(of: scrollToElement) { _, newValue in
            withAnimation(.easeInOut(duration: 0.5)) {
                proxy.scrollTo(rowIndex(viewIndex: newValue), anchor: .center)
            }
        }
    }
}

/// Use this item to force a line break in a WrappingHStack
public struct NewLine: View {
    public init() { }
    public let body = Spacer(minLength: .infinity)
}

enum ViewType {
    case any(AnyView)
    case newLine

    init<V: View>(rawView: V) {
        switch rawView {
        case is NewLine: self = .newLine
        default: self = .any(AnyView(rawView))
        }
    }
}

/// WrappingHStack is a UI Element that works in a very similar way to HStack,
///  but automatically positions overflowing elements on next lines.
///  It can be customized by using alignment (controls the alignment of the
///  items, it may get ignored when combined with `dynamicIncludingBorders`
///  or `.dynamic` spacing), spacing (use `.constant` for fixed spacing,
///  `.dynamic` to have the items fill the width of the WrappingHSTack and
///  `.dynamicIncludingBorders` to fill the full width with equal spacing
///  between items and from the items to the border.) and lineSpacing (which
///  adds a vertical separation between lines)
public struct WrappingHStack: View {
    private struct HeightPreferenceKey: PreferenceKey {
        nonisolated(unsafe) static var defaultValue = CGFloat.zero
        static func reduce(value: inout CGFloat , nextValue: () -> CGFloat) {
            value = nextValue()
        }
    }
    
    public enum Spacing {
        case constant(CGFloat)
        case dynamic(minSpacing: CGFloat)
        case dynamicIncludingBorders(minSpacing: CGFloat)
        
        internal var minSpacing: CGFloat {
            switch self {
            case .constant(let constantSpacing):
                return constantSpacing
            case .dynamic(minSpacing: let minSpacing), .dynamicIncludingBorders(minSpacing: let minSpacing):
                return minSpacing
            }
        }
    }

    let alignment: HorizontalAlignment
    let spacing: Spacing
    let lineSpacing: CGFloat
    let contentManager: ContentManager
    let scrollToElement: Int
    @State private var height: CGFloat = 0
    
    public var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                GeometryReader { geo in
                    InternalWrappingHStack (
                        width: geo.size.width,
                        alignment: alignment,
                        spacing: spacing,
                        lineSpacing: lineSpacing,
                        contentManager: contentManager,
                        scrollToElement: scrollToElement,
                        proxy: proxy
                    )
                    .anchorPreference(
                        key: HeightPreferenceKey.self,
                        value: .bounds,
                        transform: {
                            geo[$0].size.height
                        }
                    )
                }
                .frame(height: height)
                .onPreferenceChange(HeightPreferenceKey.self, perform: {
                    if abs(height - $0) > 1 {
                        height = $0
                    }
                })
            }
        }
    }
}

// Convenience inits that allows 10 Elements (just like HStack).
// Based on https://alejandromp.com/blog/implementing-a-equally-spaced-stack-in-swiftui-thanks-to-tupleview/
public extension WrappingHStack {
    @inline(__always) private static func getWidth<V: View>(of view: V) -> Double {
        if view is NewLine {
            return .infinity
        }

#if os(macOS)
        let hostingController = NSHostingController(rootView: view)
#else
        let hostingController = UIHostingController(rootView: view)
#endif
        return hostingController.sizeThatFits(in: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)).width
    }
    
    /// Instatiates a WrappingHStack
    /// - Parameters:
    ///   - data: The items to show
    ///   - id: The `KeyPath` to use as id for the items
    ///   - alignment: Controls the alignment of the items. This may get
    ///    ignored when combined with `.dynamicIncludingBorders` or
    ///    `.dynamic` spacing.
    ///   - spacing: Use `.constant` for fixed spacing, `.dynamic` to have
    ///    the items fill the width of the WrappingHSTack and
    ///    `.dynamicIncludingBorders` to fill the full width with equal spacing
    ///    between items and from the items to the border.
    ///   - lineSpacing: The distance in points between the bottom of one line
    ///    fragment and the top of the next
    ///   - content: The content and behavior of the view.
    init<Data: RandomAccessCollection, Content: View>(_ data: Data, id: KeyPath<Data.Element, Data.Element> = \.self, alignment: HorizontalAlignment = .leading, spacing: Spacing = .constant(8), lineSpacing: CGFloat = 0, scrollToElement: Int, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.spacing = spacing
        self.lineSpacing = lineSpacing
        self.alignment = alignment
        self.contentManager = ContentManager(
            items: data.map { ViewType(rawView: content($0[keyPath: id])) },
            getWidths: {
                data.map {
                    Self.getWidth(of: content($0[keyPath: id]))
                }
            })
        self.scrollToElement = scrollToElement
    }
}
