//
//  ViewController.swift
//  PRIMs
//
//  Created by Niels Taatgen on 4/17/15.
//  Copyright (c) 2015 Niels Taatgen. All rights reserved.
//

import Cocoa

class MainViewController: NSViewController,NSTableViewDataSource,NSTableViewDelegate, NSSplitViewDelegate, GraphViewDataSource, PrimViewDataSource {
    
    
    var model = Model(silent: false)
    
//    var modelCode: String? = nil
    
    @IBOutlet var modelText: NSTextView!
    
    @IBOutlet var outputText: NSTextView!
    
    @IBOutlet weak var outputScrollView: NSScrollView!
    
    @IBOutlet weak var productionTable: NSTableView!
  
    @IBOutlet weak var taskTable: NSTableView!
    
    @IBOutlet weak var chunkTable: NSTableView!
    
    @IBOutlet weak var chunkTextField: NSTextField!
    
    // Spitviews
    
    @IBOutlet weak var topSplit: NSSplitView!
    
    @IBOutlet weak var leftSplit: NSSplitView!
    
    @IBOutlet weak var middleSplit: NSSplitView!
    
    @IBOutlet weak var rightSplit: NSSplitView!
    
    @IBOutlet weak var chunkSplit: NSSplitView!
    
    
    func splitView(splitView: NSSplitView, canCollapseSubview subview: NSView) -> Bool {
        if subview === middleSplit as NSView || subview === middleSplit.subviews[0] {
            return false
        }
        return true
    }
    
    
    func splitView(splitView: NSSplitView, constrainMaxCoordinate proposedMaximumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
        if splitView === chunkSplit {
        return proposedMaximumPosition - 100
        }
        return proposedMaximumPosition - 200
    }
    
    func splitView(splitView: NSSplitView, constrainMinCoordinate proposedMinimumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
        if splitView === chunkSplit {
        return proposedMinimumPosition + 100
        }
        return proposedMinimumPosition + 200
    }
    
    func splitView(splitView: NSSplitView, shouldCollapseSubview subview: NSView, forDoubleClickOnDividerAtIndex dividerIndex: Int) -> Bool {
        return  splitView !== chunkSplit
    }
    
    func numberToColor(i: Int) -> NSColor {
        switch i {
        case -3: return NSColor.brownColor()
        case -2: return NSColor.grayColor()
        case -1: return NSColor.whiteColor()
        case 0: return NSColor.redColor()
        case 1: return NSColor.blueColor()
        case 2: return NSColor.greenColor()
        case 3: return NSColor.purpleColor()
        case 4: return NSColor.cyanColor()
        case 5: return NSColor.magentaColor()
        case 6: return NSColor.orangeColor()
        case 7: return NSColor.yellowColor()
        default: return NSColor.blackColor()
        }
    }
    
    /** This section implements the functions needed for the GraphView, which can display various performance measures
    Currently, it shows run latencies.
    The actual results are stored in the Model class
    */
    
    @IBOutlet weak var graph: GraphView! {
        didSet { graph.dataSource = self }}
    
    @IBAction func clearGraph(sender: NSButton) {
        model.clearResults()
        if model.currentTaskIndex != nil {
            model.newResult()
        }
        updateAllViews()
    }
    
    
    func graphXMin(sender: GraphView) -> Double? {
        return 0.0
    }
    
    func graphXMax(sender: GraphView) -> Double? {
        let maxX =  max(1.0, model.maxX)
        return trunc((maxX - 1)/5) * 5 + 5

    }
    
    func graphYMin(sender: GraphView) -> Double? {
        return 0.0
    }
    
    func graphYMax(sender: GraphView) -> Double? {
        return trunc(model.maxY/5) * 5 + 5
    }
    
    func graphNumberOfGraphs(sender: GraphView) -> Int {
        return model.modelResults.count
    }
    
    func graphColorOfGraph(sender: GraphView, graph: Int) -> NSColor? {
        if graph >= model.modelResults.count { return nil } else {
        return numberToColor(model.resultTaskNumber[graph])
        }
    }
    
    func graphPointsForGraph(sender: GraphView, graph: Int) -> [(Double, Double)] {
        return model.modelResults[graph]
    }
    
    /**
    This section implements the PrimGraph protocol.
    */
    
    var primGraphData: FruchtermanReingold?
    
    @IBOutlet weak var primGraph: PrimView! {
        didSet { primGraph.dataSource = self }
    }
    
    @IBAction func redisplayPrimGraph(sender: NSButton) {
        primViewCalculateGraph(primGraph)
        primGraph.needsDisplay = true
    }
    
    @IBOutlet weak var popUpMenu: NSPopUpButton!
    
    @IBAction func popUpMenuSelected(sender: NSPopUpButton) {
        primViewCalculateGraph(primGraph)
        primGraph.needsDisplay = true
    }
    
    let border = 10.0

    func primViewCalculateGraph(sender: PrimView) {
        primGraphData = FruchtermanReingold(W: Double(sender.bounds.width) - 3 * border, H: Double(sender.bounds.height) - 3 * border)
        let graphType = popUpMenu.selectedItem!.title
        switch graphType {
            case "PRIMs": primGraphData!.setUpGraph(model)
            case "Productions": primGraphData!.setUpLearnGraph(model)
            case "Declarative": primGraphData!.setUpDMGraph(model)
        default: break // Shouldn't happen
        }
        primGraphData!.calculate()
    }
    
    func primViewNumberOfVertices(sender: PrimView) -> Int {
        if primGraphData == nil {
            return 0
        } else {
            return primGraphData!.nodes.count
        }
    }

    func primViewNumbeOfEdges(sender: PrimView) -> Int {
        if primGraphData == nil {
            return 0
        } else {
            return primGraphData!.edges.count
        }
    }

    func primViewVertexCoordinates(sender: PrimView, index: Int) -> (Double, Double) {
        if primGraphData == nil {
            return (0,0)
        } else {
            let key = primGraphData!.keys[index]
            return (primGraphData!.nodes[key]!.x + border, primGraphData!.nodes[key]!.y + border)
        }
    }
    
    func primViewEdgeVertices(sender: PrimView, index: Int) -> (Int, Int) {
        if primGraphData == nil {
            return (0,0)
        } else {
            let vertex1 = primGraphData!.edges[index].from
            let vertex2 = primGraphData!.edges[index].to
            return (primGraphData!.nodeToIndex[vertex1.name]! , primGraphData!.nodeToIndex[vertex2.name]!)
        }
    }
    
    func primViewVertexColor(sender: PrimView, index: Int) -> NSColor {
        if primGraphData == nil {
            return NSColor.whiteColor()
        } else {
            let key = primGraphData!.keys[index]
            let taskNumber = primGraphData!.nodes[key]!.taskNumber
            return numberToColor(taskNumber)
        }
    }
    
    func primViewVertexLabel(sender: PrimView, index: Int) -> String {
        if primGraphData == nil {
            return ""
        } else {
            let key = primGraphData!.keys[index]
            return primGraphData!.nodes[key]!.name
        }
    }
    
    func primViewRescale(sender: PrimView, newW: Double, newH: Double) {
        if primGraphData != nil {
            primGraphData!.rescale(newW - 3 * border, newH: newH - 3 * border)
        }
    }

    func primViewVertexBroad(sender: PrimView, index: Int) -> Bool {
        if primGraphData != nil {
            let key = primGraphData!.keys[index]
            return primGraphData!.nodes[key]!.taskNode
        }
        return false
    }
    
    func primViewVertexHalo(sender: PrimView, index: Int) -> Bool {
        if primGraphData != nil {
            let key = primGraphData!.keys[index]
            return primGraphData!.nodes[key]!.halo
        }
        return false
    }
    
    @IBOutlet weak var allLabelsButton: NSButton!
    
    @IBAction func allLabelsButtonPushed(sender: NSButton) {
        primGraph.needsDisplay = true
    }
    
    func primViewVisibleLabel(sender: PrimView, index: Int) -> String? {
        if primGraphData != nil {
            let key = primGraphData!.keys[index]
            if primGraphData!.nodes[key]!.labelVisible || allLabelsButton.state == NSOnState {
                return primGraphData!.nodes[key]!.shortName
            }
        }
        return nil
    }
    
    func updatePrimGraph() {
        primGraph.needsDisplay = true
    }
    
    @IBOutlet weak var primViewView: PrimView!
    
    
    @IBAction func clickInPrimView(sender: NSClickGestureRecognizer) {
        let location = sender.locationInView(primViewView)
        if primGraphData == nil { return }
        primGraphData!.makeVisibleClosestNodeName(Double(location.x) - border,y: Double(location.y) - border)
        primGraph.needsDisplay = true
        
    }
    
    var nodeToBeMoved: Node?
    
    @IBAction func dragInPrimView(sender: NSPanGestureRecognizer) {
        let location: NSPoint = sender.locationInView(primViewView)
        switch sender.state {
        case .Began:
            nodeToBeMoved = primGraphData!.findClosest(Double(location.x) - border, y: Double(location.y) - border)
        case .Ended:
            nodeToBeMoved = nil
        default: break
        }
        if nodeToBeMoved != nil {
            nodeToBeMoved!.x = Double(location.x) - border
            nodeToBeMoved!.y = Double(location.y) - border
            primGraph.needsDisplay = true
        }
        
    }
    
    
    /// Code that handles the trace window and its popup
    
    @IBOutlet weak var traceSelectionMenu: NSPopUpButton!
    
    
    @IBAction func traceMenuSelected(sender: NSPopUpButton) {
        updateTrace()
    }
    
    func updateTrace() {
        let traceLevel = traceSelectionMenu.selectedItem!.title
        switch traceLevel {
        case "Operators only": outputText.string = model.getTrace(1)
        case "Operators and modules": outputText.string = model.getTrace(2)
        case "Operators and productions": outputText.string = model.getTrace(3)
        case "Operators, productions, compilation": outputText.string = model.getTrace(4)
        case "All": outputText.string = model.getTrace(5)
        default: break // shouldn't happen
        }
    }
    
//    @IBOutlet weak var popUpMenu: NSPopUpButton!
//    
//    @IBAction func popUpMenuSelected(sender: NSPopUpButton) {
//        primViewCalculateGraph(primGraph)
//        primGraph.needsDisplay = true
//    }
//    
//    let border = 10.0
//    
//    func primViewCalculateGraph(sender: PrimView) {
//        primGraphData = FruchtermanReingold(W: Double(sender.bounds.width) - 3 * border, H: Double(sender.bounds.height) - 3 * border)
//        let graphType = popUpMenu.selectedItem!.title
//        switch graphType {
//        case "PRIMs": primGraphData!.setUpGraph(model)
//        case "Productions": primGraphData!.setUpLearnGraph(model)
//        case "Declarative": primGraphData!.setUpDMGraph(model)
//        default: break // Shouldn't happen
//        }
//        primGraphData!.calculate()
//    }
//    
    
    /// Code to load models
    
    
    @IBAction func loadModel(sender: NSButton) {
        let fileDialog: NSOpenPanel = NSOpenPanel()
        fileDialog.prompt = "Select model file"
        fileDialog.worksWhenModal = true
        fileDialog.allowsMultipleSelection = true
        fileDialog.resolvesAliases = true
        fileDialog.allowedFileTypes = ["prims"]
        let result = fileDialog.runModal()
        if result != NSFileHandlingPanelOKButton { return }
        let URLs = fileDialog.URLs // as? [NSURL]
//        if URLs == nil { return }
        for filePath in URLs {
            if !model.loadModelWithString(filePath) {
                updateAllViews()
                return
            }
            primViewCalculateGraph(primGraph)
            primGraph.needsDisplay = true
            updateAllViews()
            NSDocumentController.sharedDocumentController().noteNewRecentDocumentURL(filePath)
        }
    }
    
//    currentTaskIndex = model.tasks.count
//    setParametersToDefault()
//    if !parseCode(modelCode!,taskNumber: tasks.count) {
//    return false
//    }
//} else {
//    return false
//}
//addTask(filePath)
//primViewCalculateGraph(primGraph)
//primGraph.needsDisplay = true
//updateAllViews()

    func respondToOpenFile(notification: NSNotification) {
        let url = notification.object as? NSURL
        if url != nil {
            model.loadModelWithString(url!)
            primViewCalculateGraph(primGraph)
            primGraph.needsDisplay = true
            updateAllViews()
        }
    }
    
    func updateAllViews() {
        model.commitToTrace(false)
        updateTrace()
//        let bottomOffset = CGPointMake(0, outputText.bounds.size.height)
//        println("bottomOffset = \(bottomOffset)")
//        outputScrollView.documentView!.scrollToPoint(bottomOffset)

        pTable = createProductionTable()
        productionTable.reloadData()
        dmTable = createDMTable()
        chunkTable.reloadData()
        taskTable.reloadData()
        graph.needsDisplay = true
        updateBufferView()
//        graph.setNeedsDisplayInRect(graph.frame)
    }
    
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        switch tableView {
        case productionTable: return pTable.count
        case taskTable: return model.tasks.count
        case chunkTable: return dmTable.count
        default: return 0
        }
    }
    
    func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject? {
        switch tableView {
        case productionTable:
            switch String(tableColumn!.identifier) {
            case "Name": return pTable[row].name
            case "Utility": return String(format:"%.2f", pTable[row].u)
            default:
                return nil
            }
        case taskTable:
            switch String(tableColumn!.identifier) {
            case "Name": return row == model.currentTaskIndex ? "** " + model.tasks[row].name : model.tasks[row].name
            case "Loaded": let text = NSMutableAttributedString(string: model.tasks[row].loaded ? "▶︎" : "")
            text.addAttribute(NSForegroundColorAttributeName, value: numberToColor(row), range: NSMakeRange(0, text.length))

                return text
            default: return nil
            }
        case chunkTable:
            let (chunkName, chunkType, chunkActivation) = dmTable[row]
            let actString = String(format: "%.2f", chunkActivation)
            return "\(chunkName) isa \(chunkType) a = \(actString)"
        default: return nil
        }
    }
    
    
    @IBAction func clickInTaskTable(sender: NSTableView) {
        if sender === taskTable && sender.selectedRow != -1 {
            model.loadOrReloadTask(sender.selectedRow)
//            modelCode = model.modelText
            updateAllViews()
        } else if sender == chunkTable && sender.selectedRow != -1 {
            let chunk = model.dm.chunks[dmTable[sender.selectedRow].0]!
            chunkTextField.stringValue = "\(chunk)\nBaselevel = \(chunk.baseLevelActivation())\nActivation = \(chunk.activation())\nReferences = \(chunk.references)\n"
            if !chunk.assocs.isEmpty {
                chunkTextField.stringValue += "Associations:\n"
                for (chunkName, assoc) in chunk.assocs {
                    chunkTextField.stringValue += "\(chunkName): \(assoc)\n"
                }
            }
        }
    }
    
    var pTable: [Production] = []
    
    func createProductionTable () -> [Production] {
        var result: [Production] = []
        for (_,p) in model.procedural.productions {
            result.append(p)
        }
        result.sortInPlace({$0.u > $1.u})
        return result
    }
    
    var dmTable: [(String,String,Double)] = []
    
    func compareChunks (x: (String, String, Double), y: (String, String, Double)) -> Bool {
        let (_,s1,a1) = x
        let (_,s2,a2) = y
        if s2 != s1 { return s2 > s1 }
        else { return a1 > a2 }
    }
    
    func createDMTable() -> [(String,String,Double)] {
        var result: [(String,String,Double)] = []
        for (_,chunk) in model.dm.chunks {
            let chunkTp = chunk.slotvals["isa"]
            let chunkType = chunkTp == nil ? "No Type" : chunkTp!.description
            result.append((chunk.name,chunkType,chunk.activation()))
        }
        result = result.sort(compareChunks)
        return result
    }
    
    
    @IBOutlet weak var bufferViewOperator: NSTextField!
    
    @IBOutlet weak var bufferViewInput: NSTextField!
    
    @IBOutlet weak var bufferViewRetrievalH: NSTextField!
    
    @IBOutlet weak var bufferViewFormerGoal: NSTextField!

    @IBOutlet weak var bufferViewGoal: NSTextField!

    @IBOutlet weak var bufferViewRetrievalNewHarvest: NSTextField!
    
    
    @IBOutlet weak var bufferViewImaginal: NSTextField!
    
    @IBOutlet weak var bufferViewAction: NSTextField!
    
    @IBOutlet weak var bufferViewRetrievalR: NSTextField!
    
    @IBOutlet weak var bufferViewImaginalAction: NSTextField!
    
    @IBOutlet weak var bufferViewFormerInput: NSTextField!
    
    func formatBuffer(bufferName: String, bufferChunk: Chunk?, bufferAbbreviation: String, showSlot0: Bool = true) -> NSAttributedString {
        let s = NSMutableAttributedString(string: bufferName, attributes: [NSFontAttributeName : NSFont.boldSystemFontOfSize(12)])
        var rest: String = ""
        if bufferChunk != nil {
            if showSlot0 {
                if let value = bufferChunk!.slotValue("slot0") {
                rest += " \(bufferAbbreviation)0 \(value.description)\n"
                }
            }
            for slotNo in 1...9 {
                if let value = bufferChunk!.slotvals["slot\(slotNo)"] {
                    rest += " \(bufferAbbreviation)\(slotNo) \(value.description)\n"
                }
            }

        }
        s.appendAttributedString(NSAttributedString(string: rest))
        return s
        
    }
    
    func formatOperator(chunk: Chunk?) -> NSAttributedString {
        let operatorName = chunk == nil ? "" : chunk!.name
        let s = NSMutableAttributedString(string: "Operator \(operatorName)\n", attributes: [NSFontAttributeName : NSFont.boldSystemFontOfSize(12)])
        var rest = ""
        if let condition = chunk?.slotvals["condition"] {
            let conditions = condition.description.componentsSeparatedByString(";")
            rest += "Conditions:"
            for element in conditions {
                rest += " \(element)"
            }
            rest += "\n"
        }
        if let action = chunk?.slotvals["action"] {
            let actions = action.description.componentsSeparatedByString(";")
            rest += "Actions:"
            for element in actions {
                rest += " \(element)"
            }
            rest += "\nConstants:\n"
        }
        s.appendAttributedString(NSAttributedString(string: rest))
        s.appendAttributedString(formatBuffer("", bufferChunk: model.formerBuffers["operator"], bufferAbbreviation: "C", showSlot0: false))
        return s
    }
    
    func updateBufferView() {
        if model.buffers["input"] == nil || model.formerBuffers["input"] == nil || model.buffers["input"]! != model.formerBuffers["input"]! {
        bufferViewInput.attributedStringValue = formatBuffer("Input\n",bufferChunk: model.buffers["input"],bufferAbbreviation: "V")
        } else {
            bufferViewInput.stringValue = ""
        }
        bufferViewRetrievalH.attributedStringValue = formatBuffer("Retrieval Hv\n", bufferChunk: model.formerBuffers["retrievalH"], bufferAbbreviation: "RT")
        let s = NSMutableAttributedString(attributedString: formatBuffer("Goal\n", bufferChunk: model.formerBuffers["goal"], bufferAbbreviation: "G"))
        s.appendAttributedString(formatBuffer("", bufferChunk: model.buffers["constants"], bufferAbbreviation: "GC", showSlot0: false))
        bufferViewFormerGoal.attributedStringValue = s
        bufferViewRetrievalR.attributedStringValue = formatBuffer("Retrieval Rq\n", bufferChunk: model.formerBuffers["retrievalR"], bufferAbbreviation: "RT")
        bufferViewAction.attributedStringValue = formatBuffer("Action\n", bufferChunk: model.formerBuffers["action"], bufferAbbreviation: "AC", showSlot0: false)
        bufferViewImaginal.attributedStringValue = formatBuffer("Imaginal\n", bufferChunk: model.formerBuffers["imaginal"], bufferAbbreviation: "WM")
        if model.buffers["imaginal"] == nil || model.formerBuffers["imaginal"] == nil || model.buffers["imaginal"]! != model.formerBuffers["imaginal"]! {
            bufferViewImaginalAction.attributedStringValue = formatBuffer("Imaginal\n", bufferChunk: model.buffers["imaginal"], bufferAbbreviation: "WM")
        } else {
            bufferViewImaginalAction.stringValue = ""
        }
        bufferViewOperator.attributedStringValue = formatOperator(model.formerBuffers["operator"])
        bufferViewFormerInput.attributedStringValue = formatBuffer("Input\n", bufferChunk: model.formerBuffers["input"], bufferAbbreviation: "V", showSlot0: true)
        if model.buffers["goal"] != nil && model.formerBuffers["goal"] != nil && model.buffers["goal"]!.slotvals["last-operator"] != nil {
            model.formerBuffers["goal"]!.slotvals["last-operator"] = model.buffers["goal"]!.slotvals["last-operator"]!
        }
        if model.buffers["goal"] == nil || model.formerBuffers["goal"] == nil || model.buffers["goal"]! != model.formerBuffers["goal"]! {
        bufferViewGoal.attributedStringValue = formatBuffer("Goal\n", bufferChunk: model.buffers["goal"], bufferAbbreviation: "G")
        } else {
            bufferViewGoal.stringValue = ""
        }
        bufferViewRetrievalNewHarvest.attributedStringValue = formatBuffer("Retrieval Hv\n", bufferChunk: model.buffers["retrievalH"], bufferAbbreviation: "RT")
    }
    
    
    @IBAction func run(sender: NSButton) {
        model.run()
        updateAllViews()
        
    }
    
    @IBAction func run10(sender: NSButton) {
        model.tracing = false
        for _ in 0..<10 { run(sender) }
        model.tracing = true
    }
    
    @IBAction func step(sender: NSButton) {
        model.step()
        updateAllViews()
        
    }
    
    @IBAction func reset(sender: NSButton) {
        model.reset(model.currentTaskIndex)
        primViewCalculateGraph(primGraph)
        primGraph.needsDisplay = true
        updateAllViews()
    }
    
    @IBAction func clearAll(sender: NSButton) {
        model = Model(silent: false)
//        modelCode = nil
        primViewCalculateGraph(primGraph)
        primGraph.needsDisplay = true
        updateAllViews()
    }
    @IBOutlet weak var batchProgressBar: NSProgressIndicator!
    
    var batchRunner: BatchRun? = nil
    
    @IBAction func runBatch(sender: NSButton) {
        let fileDialog: NSOpenPanel = NSOpenPanel()
        fileDialog.title = "Select batch script file"
        fileDialog.prompt = "Select"
        fileDialog.worksWhenModal = true
        fileDialog.allowsMultipleSelection = false
        fileDialog.resolvesAliases = true
        fileDialog.allowedFileTypes = ["bprims"]
        let result = fileDialog.runModal()
        if result != NSFileHandlingPanelOKButton { return }
        var batchScript: String
        var directory: NSURL?
        if let filePath = fileDialog.URL {
            let tmp = try? String(contentsOfURL: filePath, encoding: NSUTF8StringEncoding)
            directory = filePath.URLByDeletingLastPathComponent
            if tmp == nil { return }
            batchScript = tmp!
        } else { return }
        let saveDialog = NSSavePanel()
        saveDialog.title = "Enter the name of the outputfile"
        saveDialog.prompt = "Save"
        saveDialog.worksWhenModal = true
        saveDialog.allowsOtherFileTypes = false
        saveDialog.allowedFileTypes = ["dat","txt"]
        let name = fileDialog.URL!.URLByDeletingPathExtension!.lastPathComponent!
        saveDialog.nameFieldStringValue = name + ".dat"
        let saveResult = saveDialog.runModal()
        if saveResult != NSFileHandlingPanelOKButton { return }
        if saveDialog.URL == nil { return }
//        print("Loading script \(fileDialog.URL!) to output to \(saveDialog.URL!)")
        batchRunner = BatchRun(script: batchScript, mainModel: model, outputFile: saveDialog.URL!, controller: self, directory: directory!)
//        model.tracing = false
        batchProgressBar.doubleValue = 0
        batchProgressBar.hidden = false
        outputText.hidden = true
        outputText.needsDisplay = true
        batchProgressBar.needsDisplay = true
        batchProgressBar.displayIfNeeded()
//        model.tracing = false
        batchRunner!.runScript()
        batchProgressBar.hidden = true
        outputText.hidden = false
        outputText.needsDisplay = true
//        model.tracing = true
        updateAllViews()
    }
    
    @IBAction func loadImage(sender: NSButton) {
        let fileDialog: NSOpenPanel = NSOpenPanel()
        fileDialog.title = "Select image file for loading"
        fileDialog.prompt = "Select"
        fileDialog.worksWhenModal = true
        fileDialog.allowsMultipleSelection = false
        fileDialog.resolvesAliases = true
        fileDialog.allowedFileTypes = ["brain"]
        let result = fileDialog.runModal()
        if result != NSFileHandlingPanelOKButton { return }
        if let filePath = fileDialog.URL?.path {
            guard let m = (NSKeyedUnarchiver.unarchiveObjectWithFile(filePath) as? Model) else { return }
            model = m
            model.dm.reintegrateChunks()
        } else { return }
        updateAllViews()
    }
    
    @IBAction func saveImage(sender: NSButton) {
        let saveDialog = NSSavePanel()
        saveDialog.title = "Enter the name of the imagefile"
        saveDialog.prompt = "Save"
        saveDialog.worksWhenModal = true
        saveDialog.allowsOtherFileTypes = false
        saveDialog.allowedFileTypes = ["brain"]
        saveDialog.nameFieldStringValue = "defaultbrain.brain"
        let saveResult = saveDialog.runModal()
        if saveResult != NSFileHandlingPanelOKButton { return }
        if saveDialog.URL == nil { return }
        NSKeyedArchiver.archiveRootObject(model, toFile: saveDialog.URL!.path!)
    }
    
    func updateProgressBar() {
        batchProgressBar.doubleValue = batchRunner!.progress
        batchProgressBar.needsDisplay = true
        batchProgressBar.displayIfNeeded()

    }
 
    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MainViewController.updatePrimGraph), name: "UpdatePrimGraph", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MainViewController.updateProgressBar), name: "progress", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MainViewController.respondToOpenFile(_:)), name: "openFile", object: nil)
        
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

