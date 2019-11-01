//
//  ViewController.swift
//  PRIMs
//
//  Created by Niels Taatgen on 4/17/15.
//  Copyright (c) 2015 Niels Taatgen. All rights reserved.
//

import Cocoa
import Charts

class MainViewController: NSViewController,NSTableViewDataSource,NSTableViewDelegate, NSSplitViewDelegate,  PrimViewDataSource {
    
    
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
    
    func splitView(_ splitView: NSSplitView, canCollapseSubview subview: NSView) -> Bool {
        if subview === middleSplit as NSView || subview === middleSplit.subviews[0] {
            return false
        }
        return true
    }
    
    
    func splitView(_ splitView: NSSplitView, constrainMaxCoordinate proposedMaximumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
        if splitView === chunkSplit {
        return proposedMaximumPosition - 100
        }
        return proposedMaximumPosition - 200
    }
    
    func splitView(_ splitView: NSSplitView, constrainMinCoordinate proposedMinimumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
        if splitView === chunkSplit {
        return proposedMinimumPosition + 100
        }
        return proposedMinimumPosition + 200
    }
    
    func splitView(_ splitView: NSSplitView, shouldCollapseSubview subview: NSView, forDoubleClickOnDividerAt dividerIndex: Int) -> Bool {
        return  splitView !== chunkSplit
    }
    
    func numberToColor(_ i: Int) -> NSColor {
        switch i {
        case -3: return NSColor.brown
        case -2: return NSColor.gray
        case -1: return NSColor.white
        case 0: return NSColor.red
        case 1: return NSColor.blue
        case 2: return NSColor.green
        case 3: return NSColor.purple
        case 4: return NSColor.cyan
        case 5: return NSColor.magenta
        case 6: return NSColor.orange
        case 7: return NSColor.yellow
        default: return NSColor.black
        }
    }
    
    /** This section implements the functions needed for the GraphView, which can display various performance measures
    The actual results are stored in the Model class
     This used to be code specifically written for PRIMs, but now I have adapted the Charts framework for drawing graphs
    */
    
    @IBOutlet weak var graph: LineChartView!
    
//    @IBOutlet weak var graph: GraphView! {
//        didSet { graph.dataSource = self }}
//
    @IBAction func clearGraph(_ sender: NSButton) {
        model.clearResults()
        if model.currentTaskIndex != nil {
            model.newResult()
        }
        updateAllViews()
    }
    
    func drawGraph() {
        let theData = LineChartData()
        var maxPoints = 0 // maximum number of datapoints in any of the lists
        for data in model.modelResults {
            maxPoints = max(maxPoints, data.count)
        }
        let drawCircles = maxPoints <= 40 // we draw circles if all lists are shorter than 40
        var usedTasks = Set<Int>()
        for i in 0..<model.modelResults.count {
            var data = [ChartDataEntry]()
            var results = model.modelResults[i]
            if results.count > 1 && model.averageWindow > 1 {
                for i in 1..<results.count {
                    let index = results.count - i
                    let start = max(0,index - model.averageWindow + 1)
                    var total = 0.0
                    for j in start...index {
                        total += results[j].1
                    }
                    results[index].1 = total / Double(index - start + 1)
                }
            }
            for j in 0..<results.count {
                data.append(ChartDataEntry(x: results[j].0 , y: results[j].1 ))
            }
            let lineEntry = LineChartDataSet(values: data, label: model.tasks[model.resultTaskNumber[i]].name)
            lineEntry.drawCirclesEnabled = drawCircles
            lineEntry.circleColors = [NSUIColor.black]
            lineEntry.circleHoleRadius = 2
            lineEntry.circleRadius = 4
            lineEntry.lineWidth = 3
            lineEntry.setColor(numberToColor(model.resultTaskNumber[i]))
            if usedTasks.contains(model.resultTaskNumber[i]) {
                lineEntry.lineDashLengths = [3,2]
            } else {
                usedTasks.insert(model.resultTaskNumber[i])
            }
            theData.addDataSet(lineEntry)
        }
        graph.xAxis.labelPosition = .bottom
        graph.getAxis(.left).axisMinimum = 0
        graph.getAxis(.right).axisMinimum = 0
        graph.maxVisibleCount = 10
        graph.chartDescription!.text = model.graphTitle ?? "Reaction time"
        graph.data = theData
    }
    /*
    func graphXMin(_ sender: GraphView) -> Double? {
        return 0.0
    }
    
    func graphXMax(_ sender: GraphView) -> Double? {
        let maxX =  max(1.0, model.maxX)
        return trunc((maxX - 1)/5) * 5 + 5

    }
    
    func graphYMin(_ sender: GraphView) -> Double? {
        return 0.0
    }
    
    func graphYMax(_ sender: GraphView) -> Double? {
        if model.maxY <= 1 {
            return 1
        }
        return trunc(model.maxY/5) * 5 + 5
    }
    
    func graphNumberOfGraphs(_ sender: GraphView) -> Int {
        return model.modelResults.count
    }
    
    func graphColorOfGraph(_ sender: GraphView, graph: Int) -> NSColor? {
        if graph >= model.modelResults.count { return nil } else {
        return numberToColor(model.resultTaskNumber[graph])
        }
    }
    
    func graphPointsForGraph(_ sender: GraphView, graph: Int) -> [(Double, Double)] {
        var results = model.modelResults[graph]
        if results.count > 1 {
            for i in 1..<results.count {
                let index = results.count - i
                let start = max(0,index - model.averageWindow + 1)
                var total = 0.0
                for j in start...index {
                    total += results[j].1
                }
                results[index].1 = total / Double(index - start + 1)
            }
        }
        return results    }
    
    func graphTitle(_ sender: GraphView) -> String {
        return model.graphTitle ?? "Reaction time"
    }
    */
    
    /**
    This section implements the PrimGraph protocol.
    */
    
    var primGraphData: FruchtermanReingold?
    
    @IBOutlet weak var primGraph: PrimView! {
        didSet { primGraph.dataSource = self }
    }
    
    @IBAction func redisplayPrimGraph(_ sender: NSButton) {
        primViewCalculateGraph(primGraph)
        primGraph.needsDisplay = true
    }
    
    @IBOutlet weak var popUpMenu: NSPopUpButton!
    
    @IBAction func popUpMenuSelected(_ sender: NSPopUpButton) {
        primViewCalculateGraph(primGraph)
        primGraph.needsDisplay = true
    }
    
    let border = 10.0

    func primViewCalculateGraph(_ sender: PrimView) {
        primGraphData = FruchtermanReingold(W: Double(sender.bounds.width) - 3 * border, H: Double(sender.bounds.height) - 3 * border)
        let graphType = popUpMenu.selectedItem!.title
        switch graphType {
            case "Tasks":
                primGraphData!.constantC = 1.0
                primGraphData!.setUpGraph(model, level: 1)
            case "PRIMs":
                primGraphData!.constantC = 0.3
                primGraphData!.setUpGraph(model, level: 2)
            case "Productions": primGraphData!.setUpLearnGraph(model)
            case "Declarative": primGraphData!.setUpDMGraph(model)
        default: break // Shouldn't happen
        }
        primGraphData!.calculate(randomInit: true)
    }
    
    @IBAction func primViewReCalculateGraph(_ sender: NSButtonCell) {
        guard primGraphData != nil else { return }
        primGraphData!.calculate(randomInit: false)
        primGraph.needsDisplay = true
    }
    
    
    func primViewNumberOfVertices(_ sender: PrimView) -> Int {
        if primGraphData == nil {
            return 0
        } else {
            return primGraphData!.nodes.count
        }
    }

    func primViewNumbeOfEdges(_ sender: PrimView) -> Int {
        if primGraphData == nil {
            return 0
        } else {
            return primGraphData!.edges.count
        }
    }

    func primViewVertexCoordinates(_ sender: PrimView, index: Int) -> (Double, Double) {
        if primGraphData == nil {
            return (0,0)
        } else {
            let key = primGraphData!.keys[index]
            return (primGraphData!.nodes[key]!.x + border, primGraphData!.nodes[key]!.y + border)
        }
    }
    
    func primViewEdgeVertices(_ sender: PrimView, index: Int) -> (Int, Int) {
        if primGraphData == nil {
            return (0,0)
        } else {
            let vertex1 = primGraphData!.edges[index].from
            let vertex2 = primGraphData!.edges[index].to
            return (primGraphData!.nodeToIndex[vertex1.name]! , primGraphData!.nodeToIndex[vertex2.name]!)
        }
    }
    
    func primViewVertexColor(_ sender: PrimView, index: Int) -> NSColor {
        if primGraphData == nil {
            return NSColor.white
        } else {
            let key = primGraphData!.keys[index]
            let taskNumber = primGraphData!.nodes[key]!.taskNumber
            return numberToColor(taskNumber)
        }
    }
    
    func primViewVertexLabel(_ sender: PrimView, index: Int) -> String {
        if primGraphData == nil {
            return ""
        } else {
            let key = primGraphData!.keys[index]
            return primGraphData!.nodes[key]!.name
        }
    }
    
    func primViewRescale(_ sender: PrimView, newW: Double, newH: Double) {
        if primGraphData != nil {
            primGraphData!.rescale(newW - 3 * border, newH: newH - 3 * border)
        }
    }

    func primViewVertexBroad(_ sender: PrimView, index: Int) -> Bool {
        if primGraphData != nil {
            let key = primGraphData!.keys[index]
            return primGraphData!.nodes[key]!.taskNode
        }
        return false
    }
    
    func primViewVertexHalo(_ sender: PrimView, index: Int) -> Bool {
        if primGraphData != nil {
            let key = primGraphData!.keys[index]
            return primGraphData!.nodes[key]!.halo
        }
        return false
    }
    
    func primViewEdgeColor(_ sender: PrimView, index: Int) -> NSColor {
        guard primGraphData != nil else { return NSColor.black }
        return primGraphData!.edges[index].learned ? NSColor.red : NSColor.black
    }
    
    func primViewVertextIsRectangle(_ sender: PrimView, index: Int) -> Bool {
        guard primGraphData != nil else { return false }
        let key = primGraphData!.keys[index]
        return primGraphData!.nodes[key]!.mainTaskNode
    }
    
    @IBOutlet weak var allLabelsButton: NSButton!
    
    @IBAction func allLabelsButtonPushed(_ sender: NSButton) {
         primGraph.needsDisplay = true
    }
    
    func primViewVisibleLabel(_ sender: PrimView, index: Int) -> String? {
        if primGraphData != nil {
            let key = primGraphData!.keys[index]
            if primGraphData!.nodes[key]!.labelVisible || allLabelsButton.state == NSControl.StateValue.on  {
                return primGraphData!.nodes[key]!.shortName
            }
        }
        return nil
    }
    
    @objc func updatePrimGraph() {
        primGraph.needsDisplay = true
    }
    
    @IBOutlet weak var primViewView: PrimView!
    
    
    @IBAction func clickInPrimView(_ sender: NSClickGestureRecognizer) {
        let location = sender.location(in: primViewView)
        if primGraphData == nil { return }
        primGraphData!.makeVisibleClosestNodeName(Double(location.x) - border,y: Double(location.y) - border)
        primGraph.needsDisplay = true
        
    }
    
    var nodeToBeMoved: Node?
    
    @IBAction func dragInPrimView(_ sender: NSPanGestureRecognizer) {
        let location: NSPoint = sender.location(in: primViewView)
        switch sender.state {
        case .began:
            nodeToBeMoved = primGraphData!.findClosest(Double(location.x) - border, y: Double(location.y) - border)
            if nodeToBeMoved != nil {
                nodeToBeMoved!.fixed = true
            }
        case .ended:
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
    
    
    @IBAction func traceMenuSelected(_ sender: NSPopUpButton) {
        updateTrace()
    }
    
    func updateTrace() {
        let traceLevel = traceSelectionMenu.selectedItem!.title
        outputText.textStorage?.font = NSFont(name: "Helvetica", size: 12)
        switch traceLevel {
        case "Operators only": outputText.string = model.getTrace(1)
        case "Operators and modules": outputText.string = model.getTrace(2)
        case "Operators and productions": outputText.string = model.getTrace(3)
        case "Operators, productions, compilation": outputText.string = model.getTrace(4)
        case "All": outputText.string = model.getTrace(5)
        case "Model code":
            if model.currentTaskIndex != nil {
            let modelCode = try? String(contentsOf: model.tasks[model.currentTaskIndex!].filename as URL, encoding: String.Encoding.utf8)
            outputText.string = modelCode ?? "No model"
            } else { outputText.string = "No model" }
            outputText.textStorage?.font = NSFont(name: "Source Code Pro", size: 12)
        default: break // shouldn't happen
        }
        outputText.scrollToEndOfDocument(self)
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
    
    
    @IBAction func loadModel(_ sender: NSButton) {
        let fileDialog: NSOpenPanel = NSOpenPanel()
        fileDialog.prompt = "Select model file"
        fileDialog.worksWhenModal = true
        fileDialog.allowsMultipleSelection = true
        fileDialog.resolvesAliases = true
        fileDialog.allowedFileTypes = ["prims"]
        let result = fileDialog.runModal()
        if result != NSApplication.ModalResponse.OK { return }
        let URLs = fileDialog.urls // as? [NSURL]
//        if URLs == nil { return }
        for filePath in URLs {
            if !model.loadModelWithString(filePath) {
                updateAllViews()
                return
            }
            primViewCalculateGraph(primGraph)
            primGraph.needsDisplay = true
            updateAllViews()
            NSDocumentController.shared.noteNewRecentDocumentURL(filePath)
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

    @objc func respondToOpenFile(_ notification: Notification) {
        let url = notification.object as? URL
        if url != nil {
            _ = model.loadModelWithString(url!)
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
        drawGraph()
        if conflictTraceViewController != nil {
            conflictTraceViewController!.clear()
            conflictTraceViewController!.chunkNameTable.reloadData()
            
        }
//        graph.setNeedsDisplayInRect(graph.frame)
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        switch tableView {
        case productionTable: return pTable.count
        case taskTable: return model.tasks.count
        case chunkTable: return dmTable.count
        default: return 0
        }
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        switch tableView {
        case productionTable:
            switch tableColumn!.identifier.rawValue {
            case "Name": return pTable[row].name
            case "Utility": return String(format:"%.2f", pTable[row].u)
            default:
                return nil
            }
        case taskTable:
            switch tableColumn!.identifier.rawValue {
            case "Name": return row == model.currentTaskIndex ? "** " + model.tasks[row].name : model.tasks[row].name
            case "Loaded": let text = NSMutableAttributedString(string: model.tasks[row].loaded ? "▶︎" : "")
            text.addAttribute(NSAttributedString.Key.foregroundColor, value: numberToColor(row), range: NSMakeRange(0, text.length))

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
    
    
    @IBAction func clickInTaskTable(_ sender: NSTableView) {
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
        result.sort(by: {$0.u > $1.u})
        return result
    }
    
    var dmTable: [(String,String,Double)] = []
    
    func compareChunks (_ x: (String, String, Double), y: (String, String, Double)) -> Bool {
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
        result = result.sorted(by: compareChunks)
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
    
    func formatBuffer(_ bufferName: String, bufferChunk: Chunk?, bufferAbbreviation: String, showSlot0: Bool = true) -> NSAttributedString {
        let s = NSMutableAttributedString(string: bufferName, attributes: [NSAttributedString.Key.font : NSFont.boldSystemFont(ofSize: 12)])
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
        s.append(NSAttributedString(string: rest))
        return s
        
    }
    
    func formatOperator(_ chunk: Chunk?) -> NSAttributedString {
        let operatorName = chunk == nil ? "" : chunk!.name
        let s = NSMutableAttributedString(string: "Operator \(operatorName)\n", attributes: [NSAttributedString.Key.font : NSFont.boldSystemFont(ofSize: 12)])
        var rest = ""
        if let condition = chunk?.slotvals["condition"] {
            let conditions = condition.description.components(separatedBy: ";")
            rest += "Conditions:"
            for element in conditions {
                rest += " \(element)"
            }
            rest += "\n"
        }
        if let action = chunk?.slotvals["action"] {
            let actions = action.description.components(separatedBy: ";")
            rest += "Actions:"
            for element in actions {
                rest += " \(element)"
            }
            rest += "\nConstants:\n"
        }
        s.append(NSAttributedString(string: rest))
        s.append(formatBuffer("", bufferChunk: model.formerBuffers["operator"], bufferAbbreviation: "C", showSlot0: false))
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
        s.append(formatBuffer("", bufferChunk: model.buffers["constants"], bufferAbbreviation: "GC", showSlot0: false))
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
    
    
    @IBAction func run(_ sender: NSButton) {
        model.run()
        updateAllViews()
        
    }
    
    @IBAction func run10(_ sender: NSButton) {
        model.tracing = false
        for _ in 0..<10 { run(sender) }
        model.tracing = true
    }
    
    @IBAction func run100(_ sender: NSButton) {
        model.tracing = false
        for _ in 0..<100 { run(sender) }
        model.tracing = true
    }
    
    @IBAction func step(_ sender: NSButton) {
        model.step()
        updateAllViews()
        
    }
    
    @IBAction func reset(_ sender: NSButton) {
        model.reset(model.currentTaskIndex)
        primViewCalculateGraph(primGraph)
        primGraph.needsDisplay = true
        updateAllViews()
    }
    
    @IBAction func clearAll(_ sender: NSButton) {
        if conflictTraceWindowController != nil {
            conflictTraceWindowController!.close()
            conflictTraceViewController = nil
        }
        model = Model(silent: false)
//        modelCode = nil
        primViewCalculateGraph(primGraph)
        primGraph.needsDisplay = true
        updateAllViews()
    }
    
    var batchRunner: BatchRun? = nil
    
    @IBAction func runBatch(_ sender: NSButton) {
        let fileDialog: NSOpenPanel = NSOpenPanel()
        fileDialog.title = "Select batch script file"
        fileDialog.prompt = "Select"
        fileDialog.worksWhenModal = true
        fileDialog.allowsMultipleSelection = false
        fileDialog.resolvesAliases = true
        fileDialog.allowedFileTypes = ["bprims"]
        let result = fileDialog.runModal()
        if result != NSApplication.ModalResponse.OK { return }
        var batchScript: String
        var directory: URL?
        if let filePath = fileDialog.url {
            let tmp = try? String(contentsOf: filePath, encoding: String.Encoding.utf8)
            directory = filePath.deletingLastPathComponent()
            if tmp == nil { return }
            batchScript = tmp!
        } else { return }
        let saveDialog = NSSavePanel()
        saveDialog.title = "Enter the name of the outputfile"
        saveDialog.prompt = "Save"
        saveDialog.worksWhenModal = true
        saveDialog.allowsOtherFileTypes = false
        saveDialog.allowedFileTypes = ["dat","txt"]
        let name = fileDialog.url!.deletingPathExtension().lastPathComponent
        saveDialog.nameFieldStringValue = name + ".dat"
        let saveResult = saveDialog.runModal()
        if saveResult != NSApplication.ModalResponse.OK { return }
        if saveDialog.url == nil { return }
//        print("Loading script \(fileDialog.URL!) to output to \(saveDialog.URL!)")
        batchRunner = BatchRun(script: batchScript, mainModel: model, outputFile: saveDialog.url!, controller: self, directory: directory!)
//        model.tracing = false
        outputText.isHidden = true
        outputText.needsDisplay = true
//        model.tracing = false
        batchRunner!.runScript()
        outputText.isHidden = false
        outputText.needsDisplay = true
//        model.tracing = true
        updateAllViews()
    }
    
    @IBAction func loadImage(_ sender: NSButton) {
        let fileDialog: NSOpenPanel = NSOpenPanel()
        fileDialog.title = "Select image file for loading"
        fileDialog.prompt = "Select"
        fileDialog.worksWhenModal = true
        fileDialog.allowsMultipleSelection = false
        fileDialog.resolvesAliases = true
        fileDialog.allowedFileTypes = ["brain"]
        let result = fileDialog.runModal()
        if result != NSApplication.ModalResponse.OK { return }
        if let filePath = fileDialog.url?.path {
            guard let m = (NSKeyedUnarchiver.unarchiveObject(withFile: filePath) as? Model) else { return }
            model = m
            model.dm.reintegrateChunks()
        } else { return }
        updateAllViews()
    }
    
    @IBAction func saveImage(_ sender: NSButton) {
        let saveDialog = NSSavePanel()
        saveDialog.title = "Enter the name of the imagefile"
        saveDialog.prompt = "Save"
        saveDialog.worksWhenModal = true
        saveDialog.allowsOtherFileTypes = false
        saveDialog.allowedFileTypes = ["brain"]
        saveDialog.nameFieldStringValue = "defaultbrain.brain"
        let saveResult = saveDialog.runModal()
        if saveResult != NSApplication.ModalResponse.OK { return }
        if saveDialog.url == nil { return }
        NSKeyedArchiver.archiveRootObject(model, toFile: saveDialog.url!.path)
    }
    
    @IBAction func saveGraph(_ sender: NSButton) {
        let saveDialog = NSSavePanel()
        saveDialog.title = "Enter the name of the file"
        saveDialog.prompt = "Save"
        saveDialog.worksWhenModal = true
        saveDialog.allowsOtherFileTypes = false
        saveDialog.allowedFileTypes = ["pdf"]
        saveDialog.nameFieldStringValue = "PRIMSoutput.pdf"
        let saveResult = saveDialog.runModal()
        if saveResult != NSApplication.ModalResponse.OK { return }
        if saveDialog.url == nil { return }
        try? primGraph.dataWithPDF(inside: primGraph.bounds).write(to: saveDialog.url!)
        
    }
    
    @IBAction func saveChart(_ sender: NSButton) {
        let saveDialog = NSSavePanel()
        saveDialog.title = "Enter the name of the file"
        saveDialog.prompt = "Save"
        saveDialog.worksWhenModal = true
        saveDialog.allowsOtherFileTypes = false
        saveDialog.allowedFileTypes = ["pdf"]
        saveDialog.nameFieldStringValue = "PRIMSChartoutput.pdf"
        let saveResult = saveDialog.runModal()
        if saveResult != NSApplication.ModalResponse.OK { return }
        if saveDialog.url == nil { return }
        try? graph.dataWithPDF(inside: graph.bounds).write(to: saveDialog.url!)
    }
    
//    var conflictTraceWindow: NSWindow?
    var conflictTraceWindowController: NSWindowController?
    var conflictTraceViewController: ConflictTraceViewController?
    
    
    
    @IBAction func openConflictTraceWindow(_ sender: NSButton) {
        if conflictTraceWindowController == nil {
            let storyboard = NSStoryboard(name: "Main", bundle: nil)
            if let vc = storyboard.instantiateController(withIdentifier: "chunkView") as? ConflictTraceViewController {
                let cst = ConflictSetTrace()
                model.conflictSet = cst
                model.conflictSet!.model = model
                vc.conflictSet = cst
                conflictTraceViewController = vc
                let myWindow = NSWindow(contentViewController: vc)
                myWindow.title = "Conflict resolution trace"
                myWindow.makeKeyAndOrderFront(self)
                conflictTraceWindowController = NSWindowController(window: myWindow)
                conflictTraceWindowController?.showWindow(self)
            }
        }
        else {
            conflictTraceWindowController!.close()
            conflictTraceWindowController = nil
            conflictTraceViewController = nil
        }
    }
 
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(MainViewController.updatePrimGraph), name: NSNotification.Name(rawValue: "UpdatePrimGraph"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MainViewController.respondToOpenFile(_:)), name: NSNotification.Name(rawValue: "openFile"), object: nil)
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

