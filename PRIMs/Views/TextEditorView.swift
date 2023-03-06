//
//  TextEditorView.swift
//  PRIMs
//
//  Created by Niels Taatgen on 3/2/23.
//

import SwiftUI

struct TextEditorView: View {
    @ObservedObject var model: PRIMsViewModel
    @Binding var modelText: String

    var body: some View {
        VStack {
            Text("Editor")
            HStack {
                Button(action: {
                    if let fileURL = Bundle.main.url(forResource: "model-template", withExtension: "prims") {
                        if let fileContents = try? String(contentsOf: fileURL) {
                            modelText = fileContents
                            return
                        }
                    }
                    modelText = ""
                }) {
                    Label("New", systemImage: "doc.badge.arrow.up")
                }
                Button(action: {
                    modelText = model.modelText
                    model.setCurrentEditedModel()
                }) {
                    Label("Load", systemImage: "doc")
                }
                Button(action: {
                    model.saveCurrentModel(text: modelText)
                    
                }) {
                    Label("Save", systemImage: "pencil")
                }
                Button(action: {
                    model.saveAsCurrentModel(text: modelText)
                }) {
                    Label("Save as...", systemImage: "pencil.line")
                }
                Button(action: {
                    model.saveAndReload(text: modelText)
                    
                }) {
                    Label("Save and reload", systemImage: "goforward")
                }
            }
            TextEditor(text: $modelText)
                .font(.system(.body, design: .monospaced))
        }
        
    }
}
//
//struct TextEditorView_Previews: PreviewProvider {
//    static var previews: some View {
//        TextEditorView(model: PRIMsViewModel())
//    }
//}
