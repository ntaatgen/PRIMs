//
//  ViewController.swift
//  PRIMs
//
//  Created by Niels Taatgen on 4/17/15.
//  Copyright (c) 2015 Niels Taatgen. All rights reserved.
//

import Cocoa

class MainViewController: NSViewController,NSTableViewDataSource,NSTableViewDelegate {
    
    var modelCode: String? = nil
    
    @IBOutlet var modelText: NSTextView!
    
    @IBOutlet var bufferText: NSTextView!
    
    @IBOutlet var outputText: NSTextView!
    
    @IBOutlet weak var productionTable: NSTableView!
    
    @IBAction func loadModel(sender: NSButton) {
        var fileDialog: NSOpenPanel = NSOpenPanel()
        fileDialog.prompt = "Select model file"
        fileDialog.worksWhenModal = true
        fileDialog.allowsMultipleSelection = false
        fileDialog.resolvesAliases = true
        fileDialog.runModal()
        if let filePath = fileDialog.URL {
            modelCode = String(contentsOfURL: filePath, encoding: NSUTF8StringEncoding, error: nil)
            model.inputs = []
            parseCode()
        }
        modelText.string = modelCode
//        for (_,ch) in model.dm.chunks {
//            println("\(ch)")
//        }
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
    }
    
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return pTable.count
    }
    
    func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject? {
        switch String(tableColumn!.identifier) {
        case "Name": return pTable[row].name
        case "Utility": return String(format:"%.2f", pTable[row].u)
        default: println("***" + String(tableColumn!.identifier))
            return ""
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
    }
    
    func parseCode() {
        let parser = Parser(model: model, text: modelCode!)
        parser.parseModel()
    }
    
    
    var model = Model()
    override func viewDidLoad() {
        super.viewDidLoad()
//        let bundle = NSBundle.mainBundle()
//        let path = bundle.pathForResource("count", ofType: "prims")!
//        let modelText = String(contentsOfFile: path, encoding: NSUTF8StringEncoding, error: nil)!
//        
//        let parser = Parser(model: model, text: modelText)
//        parser.parseModel()
//        
//        var times: [Double] = []
//        for i in 0..<100 {
//            println("\n\n*** Model run \(i + 1) ***\n")
//            let start = model.time
//            model.run()
//            let latency = model.time - start
//            times.append(latency)
//            println("\n\n*** Total time \(latency) ***")
//
//        }
//        for t in times {
//            println("\(t)")
//        }
//        for (_,p) in model.procedural.productions {
//            println("\(p)")
//        }
 
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

