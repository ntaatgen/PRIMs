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
            Button(action: { model.loadModels() }) {
                Label("Load", systemImage: "doc")
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
            Toggle(isOn: $editorVisible) {
                Text("Editor")
            }

                
            
            Spacer()
        }
        .padding()

    }
}

//struct ButtonBar_Previews: PreviewProvider {
//    static var previews: some View {
//        ButtonBar(model: PRIMsViewModel(), editorVisible: true)
//    }
//}
