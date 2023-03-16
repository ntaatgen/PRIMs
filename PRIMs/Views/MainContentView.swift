//
//  MainContentView.swift
//  PRIMs
//
//  Created by Niels Taatgen on 3/2/23.
//

import SwiftUI

struct MainContentView: View {
    @ObservedObject var model: PRIMsViewModel
    @State var editorVisible =  false
    @State var conflictTraceVisible = true
    @State var modelText: String = ""
    var body: some View {
        VStack {
            ButtonBar(model: model, editorVisible: self.$editorVisible,
                      cftVisible: self.$conflictTraceVisible)
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

                        BufferView(model: model)
                    }
                }
                if conflictTraceVisible {
                    VSplitView {
                        ZStack {
                            VStack {
                                ConflictTraceView(model: model)
                                Divider()
                                Spacer()
                            }
                        }
                        ChartView(model: model)
                            .padding()
                        PrimGraphView(model: model)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding()
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

