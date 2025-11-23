////
////  File.swift
////  ReaderFeature
////
////  Created by Wit Owczarek on 23/11/2025.
////
//
//import Foundation
//import SwiftUI
//
//extension RecyclingScrollingLazyView {
//    struct RowData: Identifiable {
//        let fragmentID: Int
//        let index: Int
//        let value: ID
//
//        var id: Int { fragmentID }
//    }
//}
//
//struct RecyclingScrollingLazyView<ID: Hashable, Content: View>: View {
//    @State var visibleRange: Range<Int> = 0..<1
//    
//    let rowIDs: [ID]
//    let rowHeight: CGFloat
//    
//    @ViewBuilder
//    var content: (ID) -> Content
//    
//    var numberOfRows: Int { rowIDs.count }
//
//    private var visibleRows: [RowData] {
//        if rowIDs.isEmpty { return [] }
//        
//        let lowerBound = min(
//            max(0, visibleRange.lowerBound),
//            rowIDs.count - 1
//        )
//        let upperBound = max(
//            min(rowIDs.count, visibleRange.upperBound),
//            lowerBound + 1
//        )
//        
//        let range = lowerBound..<upperBound
//        let rowSlice = rowIDs[lowerBound..<upperBound]
//        
//        let rowData = zip(rowSlice, range).map { row in
//            RowData(
//                fragmentID: row.1 % range.count,
//                index: row.1,
//                value: row.0
//            )
//        }
//        return rowData
//    }
//    
//    var body: some View {
//        ScrollView(.vertical) {
//            OffsetLayout(
//                totalRowCount: rowIDs.count,
//                rowHeight: rowHeight
//            ) {
//                ForEach(visibleRows) { row in
//                    HStack {
//                        content(row.value)
//                        Text("\(row.fragmentID)")
//                        Text("\(row.index)")
//                    }
//                    .layoutValue(
//                       key: LayoutIndex.self, value: row.index
//                    )
////                        Text("\(row.fragmentID)")
//                }
//            }
//        }
//        .onScrollGeometryChange(
//            for: Range<Int>.self,
//            of: { geo in
//                self.computeVisibleRange(in: geo.visibleRect)
//            },
//            action: { oldValue, newValue in
//                self.visibleRange = newValue
//            }
//        )
//    }
//    
//    func computeVisibleRange(in rect: CGRect) -> Range<Int> {
//        let lowerBound = Int(
//            max(0, floor(rect.minY / rowHeight))
//        )
//        let rowsThatFitInRange = Int(
//            ceil(rect.height / rowHeight)
//        )
//        
//        let upperBound = max(
//            lowerBound + rowsThatFitInRange,
//            lowerBound + 1
//        )
//        
//        return lowerBound..<upperBound
//    }
//}
//
//struct OffsetLayout: Layout {
//    let totalRowCount: Int
//    let rowHeight: CGFloat
//    
//    func sizeThatFits(
//        proposal: ProposedViewSize,
//        subviews: Subviews,
//        cache: inout ()
//    ) -> CGSize {
//        CGSize(
//            width: proposal.width ?? 0,
//            height: rowHeight * CGFloat(totalRowCount)
//        )
//    }
//    
//    func placeSubviews(
//        in bounds: CGRect,
//        proposal: ProposedViewSize,
//        subviews: Subviews,
//        cache: inout ()
//    ) {
//        for subview in subviews {
//            let index = subview[LayoutIndex.self]
//            subview.place(
//                at: CGPoint(
//                    x: bounds.midX,
//                    y: bounds.minY + rowHeight * CGFloat(index)
//                ),
//                anchor: .top,
//                proposal: .init(
//                    width: proposal.width, height: rowHeight
//                )
//            )
//        }
//    }
//}
//
//struct LayoutIndex: LayoutValueKey {
//    nonisolated(unsafe) static var defaultValue: Int = 0
//    
//    typealias Value = Int
//}
//
//
//#Preview {
//    let numbers = Array(0...100)
//    
//    RecyclingScrollingLazyView(
//        rowIDs: numbers,
//        rowHeight: 42
//    ) { id in
//        Text("Bruh \(id)")
//    }
//}
