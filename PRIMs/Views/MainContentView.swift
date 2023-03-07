//
//  MainContentView.swift
//  PRIMs
//
//  Created by Niels Taatgen on 3/2/23.
//

import SwiftUI

struct MainContentView: View {
    @ObservedObject var model: PRIMsViewModel
    @State var editorVisible =  true
    @State var modelText: String = ""
    var body: some View {
        VStack {
            ButtonBar(model: model, editorVisible: self.$editorVisible)
                .layoutPriority(-1)
            HSplitView {
                if editorVisible {
                    ZStack {
                        TextEditorView(model: model, modelText: $modelText)
                    }
                }
                VSplitView {
                    ZStack {
                        TraceView(model: model)
                    }
                    TaskView(model: model)
                }
                
                ZStack {
                    VSplitView {
                        DMView(model: model)
                        ChartView(model: model)
                            .padding()
                        BufferView(model: model)
                    }
                }
            }

            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }

    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        MainContentView(model: PRIMsViewModel())
    }
}

