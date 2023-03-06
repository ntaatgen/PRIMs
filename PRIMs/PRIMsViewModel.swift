//
//  PRIMsViewModel.swift
//  PRIMs
//
//  Created by Niels Taatgen on 3/2/23.
//

import SwiftUI

class PRIMsViewModel: ObservableObject {
    @Published private var model = ModelS()
    
    var traceText: String {
        model.traceText
    }
    var modelText: String {
        model.modelText
    }
    
    var dmContent: [PublicChunk] {
        model.dmContent
    }
    
    var bufferContent: [String:Chunk] {
        model.bufferContent
    }
    
    var currentlyEditedModel: URL?

    var operatorString: String {
        model.operatorString
    }
    
    var formerGoal: String {
        model.formerGoal
    }
    
    var newGoal: String {
        model.newGoal
    }
    var formerInput: String {
        model.formerInput
    }
    
    var newInput: String {
        model.newInput
    }
    
    var modelAction: String {
        model.action
    }
    
    var formerRetrievalHarvest: String {
        model.formerRetrievalHarvest
    }
    
    var retrievalRequest: String {
        model.retrievalRequest
    }
    
    var newRetrievalHarvest: String {
        model.newRetrievalHarvest
    }
    
    var formerImaginal: String {
        model.formerImaginal
    }
    
    var newImaginal: String {
        model.newImaginal
    }
    
    var modelResults: [ModelData] {
        model.modelResults
    }
    
    var tasks: [Task] {
        model.tasks
    }
    
    var currentTask: String? {
        model.currentTask
    }

    // MARK: - Intent(s)
    
    func loadModels() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = true
        if panel.runModal() == .OK {
            for url in panel.urls {
                    model.loadModel(filePath: url)
            }
        }
    }
    
    func setCurrentEditedModel() {
        currentlyEditedModel = model.currentModelURL
    }
    
    func saveCurrentModel(text: String) {
        guard currentlyEditedModel != nil else { return saveAsCurrentModel(text: text) }
        do {
            try text.write(to: currentlyEditedModel!, atomically: false, encoding: .utf8)
        }
        catch let error as NSError {
            print("Ooops! Something went wrong: \(error)")
        }
    }
    
    func saveAsCurrentModel(text: String)  {
        let savePanel = NSSavePanel()
        savePanel.title = "Save model file"
        savePanel.nameFieldLabel = "File Name:"
        savePanel.begin { (result: NSApplication.ModalResponse) -> Void in
            if result == NSApplication.ModalResponse.OK {
                    if let panelURL = savePanel.url {
                        do {
                            try text.write(to: panelURL, atomically: false, encoding: .utf8)
                        }
                        catch let error as NSError {
                            print("Ooops! Something went wrong: \(error)")
                            self.currentlyEditedModel = nil
                            return
                        }
                        self.currentlyEditedModel = panelURL
                    }
                }
            
        }
    }
    
    func saveAndReload(text: String) {
        saveCurrentModel(text: text)
        model.clear()
        if currentlyEditedModel != nil {
            model.loadModel(filePath: currentlyEditedModel!)
            model.update()
        }
    }
    
    func run() {
        model.run()
    }
    
    func runMultiple(_ runs: Int) {
        model.runMultiple(runs)
    }
    
    func step() {
        model.step()
    }
    
    func setTraceLevel(level: Int) {
        model.traceLevel = level
        model.update()
    }
    
    func setCurrentTask(task: Task) {
        model.setCurrentTask(task: task)
    }
}

// HACK to work-around the smart quote issue
extension NSTextView {
    open override var frame: CGRect {
        didSet {
            self.isAutomaticQuoteSubstitutionEnabled = false
        }
    }
}
