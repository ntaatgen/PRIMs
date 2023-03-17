//
//  TraceView.swift
//  PRIMs
//
//  Created by Niels Taatgen on 3/2/23.
//

import SwiftUI


struct TraceView: View {
    @ObservedObject var model: PRIMsViewModel
//    @State var options = ["Operators Only", "+ Modules", "+ Productions", "+ Compilation", "All"]
    @State var selectedItem = 1
    var body: some View {
        VStack {
            Text("Trace")
            Picker("Trace detail", selection: $selectedItem) {
                Text("Operators only").tag(1)
                Text(" + Modules").tag(2)
                Text(" + Productions").tag(3)
                Text(" + Compilation").tag(4)
                Text("All").tag(5)
            }
            .onChange(of: selectedItem, perform: { tag in model.setTraceLevel(level: tag)} )
            .padding()
                ScrollView {
                    HStack {
                        Text(model.traceText)
                            .textSelection(.enabled)
                            .multilineTextAlignment(.leading)
                    Spacer()
                    }
                }
                .frame(maxWidth: .infinity,maxHeight: .infinity)
                .background(Color.white)
        }
        .padding()
    }
}
