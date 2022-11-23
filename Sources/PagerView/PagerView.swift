//
//  PagerView.swift
//  PagerView
//
//  Created by yukonblue on 10/31/2022.
//

import SwiftUI

/// https://gist.github.com/mecid/e0d4d6652ccc8b5737449a01ee8cbc6f
public struct PagerView<Content: View>: View {

    let pageCount: Int
    let content: Content

    @State var ignore: Bool = false

    @State var currentFloatIndex: CGFloat = 0 {
        didSet {
            ignore = true
            currentIndex = min(max(Int(currentFloatIndex.rounded()), 0), self.pageCount - 1)
            ignore = false
        }
    }

    @Binding var currentIndex: Int {
        didSet {
            if (!ignore) {
                currentFloatIndex = CGFloat(currentIndex)
            }
        }
    }

    @GestureState private var offsetX: CGFloat = 0

    public init(pageCount: Int,
                currentIndex: Binding<Int>,
                @ViewBuilder content: () -> Content
    ) {
        self.pageCount = pageCount
        self._currentIndex = currentIndex
        self.content = content()
    }

    public var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                self.content.frame(width: geometry.size.width)
            }
            .frame(width: geometry.size.width, alignment: .leading)
            .offset(x: -CGFloat(self.currentFloatIndex) * geometry.size.width)
            .offset(x: self.offsetX)
            .animation(.linear, value:offsetX)
            .highPriorityGesture(
                DragGesture().updating(self.$offsetX) { value, state, _ in
                    state = value.translation.width
                }
                .onEnded({ (value) in
                    let offset = value.translation.width / geometry.size.width
                    let offsetPredicted = value.predictedEndTranslation.width / geometry.size.width
                    let newIndex = CGFloat(self.currentFloatIndex) - offset
                    
                    self.currentFloatIndex = newIndex
                    
                    withAnimation(.easeOut) {
                        if(offsetPredicted < -0.5 && offset > -0.5) {
                            self.currentFloatIndex = CGFloat(min(max(Int(newIndex.rounded() + 1), 0), self.pageCount - 1))
                        } else if (offsetPredicted > 0.5 && offset < 0.5) {
                            self.currentFloatIndex = CGFloat(min(max(Int(newIndex.rounded() - 1), 0), self.pageCount - 1))
                        } else {
                            self.currentFloatIndex = CGFloat(min(max(Int(newIndex.rounded()), 0), self.pageCount - 1))
                        }
                    }
                })
            )
        }
        .onChange(of: currentIndex, perform: { value in
            // this is probably animated twice, if the tab change occurs because of the drag gesture
            withAnimation(.easeOut) {
                currentFloatIndex = CGFloat(value)
            }
        })
    }
}

struct PagerView_Previews: PreviewProvider {
    static var previews: some View {
        PagerView(pageCount: 3, currentIndex: .constant(0)) {
            Text("1")
                .background(.red)
            Text("2")
                .background(.blue)
            Text("3")
                .background(.green)
        }
    }
}
