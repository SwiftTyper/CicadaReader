//
//  File.swift
//  ReaderFeature
//
//  Created by Wit Owczarek on 23/11/2025.
//

import Foundation
import SwiftUI

enum ViewType {
    case any(AnyView)

    init<V: View>(rawView: V) {
        switch rawView {
        default: self = .any(AnyView(rawView))
        }
    }
}

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

/// This class manages content and the calculation of their widths (reusing it).
/// It should be reused whenever possible.

@Observable
class ContentManager<Data: RandomAccessCollection & RangeReplaceableCollection> {
    var data: Data
    var widths: [Double]
    var layout: [Int] = []
    
    var previousWidth: Double? = nil
    
    init(
        data: Data,
        getWidths: @escaping () -> [Double]
    ) {
        self.data = data
        self.widths = getWidths()
    }
    
    func isVisible(viewIndex: Int) -> Bool {
        widths[viewIndex] > 0
    }
    
    func calculateLayoutAppend(
        items: Data,
        widths: [Double],
        previousFirstOfEach: [Int] = [],
        previousTrailingWidth: Double? = nil,
        width: Double,
        spacing: Spacing
    ) {
        var firstOfEach = previousFirstOfEach
        var currentWidth = previousTrailingWidth ?? width
        
        for index in (previousFirstOfEach.last ?? 0)..<items.count {
            guard widths[index] > 0 else { continue }

            let itemWidth = widths[index]

            if currentWidth + itemWidth + spacing.minSpacing > width {
                currentWidth = itemWidth
                firstOfEach.append(index)
            } else {
                currentWidth += itemWidth + spacing.minSpacing
            }
        }
        
        self.previousWidth = currentWidth
        self.layout = firstOfEach
    }
}

/// This View draws the WrappingHStack content taking into account the passed width, alignment and spacings.
/// Note that the passed LineManager and ContentManager should be reused whenever possible.
struct InternalWrappingHStack<Data: RandomAccessCollection & RangeReplaceableCollection, Content: View>: View {
    let width: CGFloat
    let alignment: HorizontalAlignment
    let spacing: Spacing
    let lineSpacing: CGFloat
    
    let scrollToElement: Int
    let proxy: ScrollViewProxy
    
    let content: (Data.Element, Data) -> Content
    let loadMoreData: () async -> Data
    
    @State private var isLoading: Bool = false
    @Environment(ContentManager<Data>.self) var cache

    init(
        width: CGFloat,
        alignment: HorizontalAlignment,
        spacing: Spacing,
        lineSpacing: CGFloat,
        scrollToElement: Int,
        proxy: ScrollViewProxy,
        @ViewBuilder content: @escaping (Data.Element, Data) -> Content,
        loadMoreData: @escaping () async -> Data
    ) {
        self.width = width
        self.alignment = alignment
        self.spacing = spacing
        self.lineSpacing = lineSpacing
        self.scrollToElement = scrollToElement
        self.proxy = proxy
        self.content = content
        self.loadMoreData = loadMoreData
    }
    
    
    func rowIndex(viewIndex: Int) -> Int {
        return max((cache.layout.firstIndex(where: { $0 > viewIndex }) ?? 0) - 1 , 0)
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

    var totalLines: Int { cache.layout.count }
    
    func startOf(line i: Int) -> Int {
        cache.layout[i]
    }

    func endOf(line i: Int) -> Int {
        i == totalLines - 1 ? cache.data.count - 1 : cache.layout[i + 1] - 1
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
                    
                    ForEach(startOf(line: lineIndex)...endOf(line: lineIndex), id: \.self) {
                        if case .dynamicIncludingBorders = spacing,
                            startOf(line: lineIndex) == $0
                        {
                            Spacer(minLength: spacing.minSpacing)
                        }
                        
                        if cache.isVisible(viewIndex: $0) {
                            content(cache.data[offset: $0], cache.data)
                        }
                        
                        if endOf(line: lineIndex) != $0 {
                            if !cache.isVisible(viewIndex: $0) {
                                
                            } else {
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
                .task {
                    if max(0, totalLines - 10) == lineIndex {
                        guard !isLoading else { return }
                        isLoading = true
                        let newData = await loadMoreData()
                        self.cache.data.append(contentsOf: newData)
                        
                        let newWidths = self.cache.data.map { Self.getWidth(of: content($0[keyPath: \.self], self.cache.data)) }
                        self.cache.widths.append(contentsOf: newWidths)
                        
                        self.cache.calculateLayoutAppend(
                            items: cache.data,
                            widths: cache.widths,
                            previousFirstOfEach: cache.layout,
                            previousTrailingWidth: cache.previousWidth,
                            width: width,
                            spacing: spacing
                        )
                        
                        isLoading = false
                    }
                }
            }
        }
        .onChange(of: scrollToElement) { _, newValue in
            withAnimation(.easeInOut(duration: 0.5)) {
                proxy.scrollTo(rowIndex(viewIndex: newValue), anchor: .center)
            }
        }
        .onAppear {
            cache.calculateLayoutAppend(
                items: cache.data,
                widths: cache.widths,
                width: width,
                spacing: spacing
            )
        }
    }
}

public struct WrappingHStack<Data: RandomAccessCollection & RangeReplaceableCollection, Content: View>: View {
    let alignment: HorizontalAlignment
    let spacing: Spacing
    let lineSpacing: CGFloat
    let scrollToElement: Int
    
    let content: (Data.Element, Data) -> Content
    let loadMoreData: () async -> Data
    
    @State private var height: CGFloat = 0
    @State var cache: ContentManager<Data>
    
    public var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                GeometryReader { geo in
                    InternalWrappingHStack(
                        width: geo.size.width,
                        alignment: alignment,
                        spacing: spacing,
                        lineSpacing: lineSpacing,
                        scrollToElement: scrollToElement,
                        proxy: proxy,
                        content: content,
                        loadMoreData: loadMoreData
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
        .environment(cache)
    }
}

public extension WrappingHStack {
    init(
        _ initialData: Data,
        id: KeyPath<Data.Element, Data.Element> = \.self,
        alignment: HorizontalAlignment = .leading,
        spacing: Spacing = .constant(8),
        lineSpacing: CGFloat = 0,
        scrollToElement: Int,
        @ViewBuilder content: @escaping (Data.Element, Data) -> Content,
        loadMoreData: @escaping () async -> Data
    ){
        self.spacing = spacing
        self.lineSpacing = lineSpacing
        self.alignment = alignment
        self._cache = State(initialValue: ContentManager(
            data: initialData,
            getWidths: { initialData.map { Self.getWidth(of: content($0[keyPath: id], initialData)) } })
        )
        self.scrollToElement = scrollToElement
        self.content = content
        self.loadMoreData = loadMoreData
    }
}

private extension RandomAccessCollection {
    subscript(offset offset: Int) -> Element {
        self[index(startIndex, offsetBy: offset)]
    }
}
