//
//  ViewController.swift
//  PRIMs
//
//  Created by Niels Taatgen on 4/17/15.
//  Copyright (c) 2015 Niels Taatgen. All rights reserved.
//

import Cocoa

class MainViewController: NSViewController,NSTableViewDataSource,NSTableViewDelegate, GraphViewDataSource {
    
    
    var model = Model()
    
    var modelCode: String? = nil
    
    @IBOutlet var modelText: NSTextView!
    
    @IBOutlet var bufferText: NSTextView!
    
    @IBOutlet var outputText: NSTextView!
    
    @IBOutlet weak var productionTable: NSTableView!
  
    @IBOutlet weak var taskTable: NSTableView!
    
    @IBOutlet weak var graph: GraphView! {
        didSet { graph.dataSource = self }}
    
    @IBAction func clearGraph(sender: NSButton) {
        model.clearResults()
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
        switch graph {
            case 0: return NSColor.redColor()
            case 1: return NSColor.blueColor()
            case 2: return NSColor.greenColor()
            case 3: return NSColor.purpleColor()
        default: return NSColor.blackColor()
        }
    }
    
    func graphPointsForGraph(sender: GraphView, graph: Int) -> [(Double, Double)] {
        return model.modelResults[graph]
    }
    
    var tasks: [Task] = []
    var currentTask: Int? = nil
    
    @IBAction func loadModel(sender: NSButton) {
        var fileDialog: NSOpenPanel = NSOpenPanel()
        fileDialog.prompt = "Select model file"
        fileDialog.worksWhenModal = true
        fileDialog.allowsMultipleSelection = false
        fileDialog.resolvesAliases = true
        fileDialog.allowedFileTypes = ["prims"]
        fileDialog.runModal()
        if let filePath = fileDialog.URL {
            modelCode = String(contentsOfURL: filePath, encoding: NSUTF8StringEncoding, error: nil)
            model.inputs = []
            if modelCode != nil {
                model.parseCode(modelCode!)
            }
            let newTask = Task(name: model.currentTask!, path: filePath)
            newTask.inputs = model.inputs
            newTask.loaded = true
            tasks.append(newTask)
            currentTask = tasks.count - 1
        }
        modelText.string = modelCode
        updateAllViews()
    }
    
    func loadOrReloadTask(i: Int) {
        if (i != currentTask) {
            modelCode = String(contentsOfURL: tasks[i].filename, encoding: NSUTF8StringEncoding, error: nil)
            if !tasks[i].loaded && modelCode != nil {
                model.parseCode(modelCode!)
                tasks[i].loaded = true
            }
            modelText.string = modelCode
            if modelCode != nil {
                model.modelText = modelCode!
            }
            model.inputs = tasks[i].inputs
            model.currentTask = tasks[i].name
            currentTask = i
            model.newResult()
            updateAllViews()
        }
    }
    
    func updateAllViews() {
        outputText.string = model.trace
        var s: String = ""
        for (bufferName, bufferChunk) in model.buffers {
            s += "=" + bufferName + ">" + "\n"
            for slot in bufferChunk.printOrder {
                s += "  " + slot + " " + bufferChunk.slotvals[slot]!.description + "\n"
            }
            s += "\n"
        }
        bufferText.string = s
        pTable = createProductionTable()
        productionTable.reloadData()
        taskTable.reloadData()
        graph.needsDisplay = true
        
//        graph.setNeedsDisplayInRect(graph.frame)
    }
    
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        switch tableView {
        case productionTable: return pTable.count
        case taskTable: return tasks.count
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
            case "Name": return row == currentTask ? "** " + tasks[row].name : tasks[row].name
            case "Loaded": return tasks[row].loaded ? "Yes" : "No"
            default: return nil
            }
        default: return nil
        }
    }
    
    
    @IBAction func clickInTaskTable(sender: NSTableView) {
        if sender === taskTable && sender.selectedRow != -1 {
            loadOrReloadTask(sender.selectedRow)
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
    
    @IBAction func run(sender: NSButton) {
        model.run()
        updateAllViews()
        
    }
    
    @IBAction func run10(sender: NSButton) {
        for i in 0..<10 { run(sender) }
    }
    
    @IBAction func step(sender: NSButton) {
        model.step()
        updateAllViews()
        
    }
    
    @IBAction func reset(sender: NSButton) {
        model.reset()
        for task in tasks {
            task.loaded = false
        }
        if currentTask != nil {
            tasks[currentTask!].loaded = true
        }
        updateAllViews()
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

