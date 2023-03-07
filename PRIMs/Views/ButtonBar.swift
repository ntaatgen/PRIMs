//
//  ButtonBar.swift
//  PRIMs
//
//  Created by Niels Taatgen on 3/2/23.
//

import SwiftUI

struct ButtonBar: View {
    @ObservedObject var model: PRIMsViewModel
    @Binding var editorVisible: Bool

    var body: some View {
        HStack() {
            Toggle(isOn: $editorVisible) {
                Label("Editor", systemImage: "doc")
            }
            .toggleStyle(.button)
            Divider()
            Button(action: { model.loadModels() }) {
                Label("Load", systemImage: "square.and.arrow.down")
            }
            Button(action: { model.step()}) {
                Label("Step", systemImage: "forward.frame")
            }
            Button(action: { model.run() }) {
                Label("Run", systemImage: "play")
            }
            Button(action: { model.runMultiple(10)}) {
                Label("Run 10", systemImage: "goforward.10")
            }


                
            
            Spacer()
        }
        .padding()

    }
}


