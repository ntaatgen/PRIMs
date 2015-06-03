//
//  ViewController.swift
//  PRIMs
//
//  Created by Niels Taatgen on 4/17/15.
//  Copyright (c) 2015 Niels Taatgen. All rights reserved.
//

import Cocoa

class MainViewController: NSViewController,NSTableViewDataSource,NSTableViewDelegate, NSSplitViewDelegate, GraphViewDataSource, PrimViewDataSource {
    
    
    var model = Model()
    
    var modelCode: String? = nil
    
    @IBOutlet var modelText: NSTextView!
    
    @IBOutlet var bufferText: NSTextView!
    
    @IBOutlet var outputText: NSTextView!
    
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
        if subview === middleSplit as NSView || subview === middleSplit.subviews[0] as! NSView {
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
        case -2: return NSColor.grayColor()
        case -1: return NSColor.whiteColor()
        case 0: return NSColor.redColor()
        case 1: return NSColor.blueColor()
        case 2: return NSColor.greenColor()
        case 3: return NSColor.purpleColor()
        case 4: return NSColor.cyanColor()
        case 5: return NSColor.magentaColor()
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
        model.newResult()
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
        primGraphData = FruchtermanReingold(W: Double(sender.bounds.width) - 2 * border, H: Double(sender.bounds.height) - 2 * border)
        let graphType = popUpMenu.selectedItem!.title
        switch graphType {
            case "PRIMs": primGraphData!.setUpGraph(model)
            case "Productions": primGraphData!.setUpLearnGraph(model)
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
    

    
    @IBAction func loadModel(sender: NSButton) {
        var fileDialog: NSOpenPanel = NSOpenPanel()
        fileDialog.prompt = "Select model file"
        fileDialog.worksWhenModal = true
        fileDialog.allowsMultipleSelection = false
        fileDialog.resolvesAliases = true
        fileDialog.allowedFileTypes = ["prims"]
        let result = fileDialog.runModal()
        if result != NSFileHandlingPanelOKButton { return }
        if let filePath = fileDialog.URL {
            modelCode = String(contentsOfURL: filePath, encoding: NSUTF8StringEncoding, error: nil)
            model.inputs = []
            if modelCode != nil {
                model.scenario = PRScenario()
                model.parameters = []
                model.inputs = []
                model.currentTaskIndex = model.tasks.count
                model.setParametersToDefault()
                if !model.parseCode(modelCode!,taskNumber: model.tasks.count) {
                    updateAllViews()
                    return
                }
            }
            let newTask = Task(name: model.currentTask!, path: filePath)
            newTask.inputs = model.inputs
            newTask.loaded = true
            newTask.goalChunk = model.currentGoals
            newTask.goalConstants = model.currentGoalConstants
            newTask.parameters = model.parameters
            newTask.scenario = model.scenario
            model.tasks.append(newTask)
//            model.currentTaskIndex = model.tasks.count - 1
        }
//        modelText.string = modelCode
        primViewCalculateGraph(primGraph)
        primGraph.needsDisplay = true
        updateAllViews()
    }
    
       
    func updateAllViews() {
        model.commitToTrace(false)
        outputText.string = model.trace
        var s: String = ""
        for (bufferName, bufferChunk) in model.buffers {
            s += "=" + bufferName + ">" + "\n"
            for slot in bufferChunk.printOrder {
                if bufferChunk.slotvals[slot]?.description != nil {
                s += "  " + slot + " " + bufferChunk.slotvals[slot]!.description + "\n"
                }
            }
            s += "\n"
        }
        bufferText.string = s
        pTable = createProductionTable()
        productionTable.reloadData()
        dmTable = createDMTable()
        chunkTable.reloadData()
        taskTable.reloadData()
        graph.needsDisplay = true
        
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
            modelCode = model.modelText
            updateAllViews()
        } else if sender == chunkTable && sender.selectedRow != -1 {
            let chunk = model.dm.chunks[dmTable[sender.selectedRow].0]!
            chunkTextField.stringValue = "\(chunk)\nActivation = \(chunk.activation())\n"
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
        result.sort({$0.u > $1.u})
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
        result = sorted(result, compareChunks)
        return result
    }
    
    @IBAction func run(sender: NSButton) {
        model.run()
        updateAllViews()
        
    }
    
    @IBAction func run10(sender: NSButton) {
        model.tracing = false
        for i in 0..<10 { run(sender) }
        model.tracing = true
    }
    
    @IBAction func step(sender: NSButton) {
        model.step()
        updateAllViews()
        
    }
    
    @IBAction func reset(sender: NSButton) {
        model.reset(model.currentTaskIndex!)

        primViewCalculateGraph(primGraph)
        primGraph.needsDisplay = true
        updateAllViews()
    }
    
    @IBAction func runBatch(sender: NSButton) {
        var fileDialog: NSOpenPanel = NSOpenPanel()
        fileDialog.title = "Select batch script file"
        fileDialog.prompt = "Select"
        fileDialog.worksWhenModal = true
        fileDialog.allowsMultipleSelection = false
        fileDialog.resolvesAliases = true
        fileDialog.allowedFileTypes = ["bprims"]
        let result = fileDialog.runModal()
        if result != NSFileHandlingPanelOKButton { return }
        var batchScript: String
        if let filePath = fileDialog.URL {
            let tmp = String(contentsOfURL: filePath, encoding: NSUTF8StringEncoding, error: nil)
            if tmp == nil { return }
            batchScript = tmp!
        } else { return }
        let saveDialog = NSSavePanel()
        saveDialog.title = "Enter the name of the outputfile"
        saveDialog.prompt = "Save"
        saveDialog.worksWhenModal = true
        saveDialog.allowsOtherFileTypes = false
        saveDialog.allowedFileTypes = ["dat","txt"]
        let saveResult = saveDialog.runModal()
        if saveResult != NSFileHandlingPanelOKButton { return }
        if saveDialog.URL == nil { return }
        println("Loading script \(fileDialog.URL!) to output to \(saveDialog.URL!)")
        let batchRunner = BatchRun(script: batchScript, outputFile: saveDialog.URL!, model: model)
        batchRunner.runScript()
    }
 
    override func viewDidLoad() {
        super.viewDidLoad()
 
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

