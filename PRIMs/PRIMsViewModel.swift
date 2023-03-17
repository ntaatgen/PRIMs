//
//  PRIMsViewModel.swift
//  PRIMs
//
//  Created by Niels Taatgen on 3/2/23.
//

import SwiftUI

class PRIMsViewModel: ObservableObject {
    @Published var model = ModelS()
    @Published private var batchModel: BatchRun?
    
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(PRIMsViewModel.updatePrimsGraph(_:)), name: NSNotification.Name(rawValue: "UpdatePrimsGraph"), object: nil)
    }
    
    var traceText: String {
        if batchModel == nil {
            return model.traceText
        } else {
            return batchModel!.traceText
        }
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
    
    var chunkTexts: [ChunkText] {
        model.chunkTexts
    }
    
    var chartTitle: String {
        model.chartTitle
    }
    
    var graphData: GraphData? {
        model.graphData
    }

    // MARK: - Intent(s)
    
    func loadModels() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = true
        panel.allowedFileTypes = ["prims"]
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
        savePanel.allowedFileTypes = [".prims"]
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
    
    @objc func updateTrace(_ notification: Notification) {
        print("received notification")
        guard batchModel != nil else {
            print("Batchmodel is nil")
            return }
        print(batchModel!.traceText)
        model.traceText = batchModel!.traceText
    }
    
    @objc func updatePrimsGraph(_ notification: Notification) {
        model.updatePrimViewData()
        print("Updated PRIMView")
    }
    
    func runBatch() {
        NotificationCenter.default.addObserver(self, selector: #selector(PRIMsViewModel.updateTrace(_:)), name: NSNotification.Name(rawValue: "updateTrace"), object: nil)

        let panel = NSOpenPanel()
        panel.title = "Script file"
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
//        panel.allowedFileTypes = [".bprims"]
        guard panel.runModal() == .OK else {
            return
        }
        let scriptCode = try? String(contentsOf: panel.url!, encoding: String.Encoding.utf8)
        guard scriptCode != nil else { return }
        let name = panel.url!.deletingPathExtension().lastPathComponent
        let savePanel = NSSavePanel()
        savePanel.title = "Save output file"
        savePanel.nameFieldLabel = "File Name:"
//        savePanel.allowedFileTypes = [".dat",".txt"]
        savePanel.nameFieldStringValue = name + ".txt"
        savePanel.begin { (result: NSApplication.ModalResponse) -> Void in
            if result == NSApplication.ModalResponse.OK {
                if let outputURL = savePanel.url, let scriptURL = panel.url {
                    self.batchModel = BatchRun(script: scriptCode!, mainModel: self.model.model, outputFile: outputURL, directory: scriptURL.deletingLastPathComponent())
                    self.batchModel?.runScript()
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
    
    func reset() {
        model.reset()
    }
    
    func clear() {
        model.clear()
    }
    
    func primViewCalculateGraph() {
        model.primViewCalculateGraph()
        model.updatePrimViewData()
    }
    
    func changeLevel(level: Int) {
        model.changeLevel(newLevel: level)
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

func numberToColor(_ i: Int) -> Color {
    switch i {
    case -3: return Color.brown
    case -2: return Color.gray
    case -1: return Color.white
    case 0: return Color.red
    case 1: return Color.blue
    case 2: return Color.green
    case 3: return Color.purple
    case 4: return Color.cyan
    case 5: return Color.indigo
    case 6: return Color.orange
    case 7: return Color.yellow
    default: return Color.black
    }
}
