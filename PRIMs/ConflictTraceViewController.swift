//
//  ConflictTraceViewController.swift
//  PRIMs
//
//  Created by Niels Taatgen on 29/4/18.
//  Copyright © 2018 Niels Taatgen. All rights reserved.
//

import Cocoa


class ConflictTraceViewController: NSViewController, NSTableViewDataSource,NSTableViewDelegate {
    
    
    var conflictSet: ConflictSetTrace!
    var selectedRow: Int? = nil
    @IBOutlet weak var chunkNameTable: NSTableView!
    
    
    @IBOutlet weak var chunkDescriptionTextField: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        chunkNameTable.dataSource = self
        chunkNameTable.dataSource = self
        chunkNameTable.reloadData()
    }
    
    func clear() {
        chunkDescriptionTextField.stringValue = ""
        if selectedRow != nil {
            chunkNameTable.deselectRow(selectedRow!)
        }
        selectedRow = nil
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return min(conflictSet.maxTableSize, conflictSet.chunks.count)
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        guard row < conflictSet.chunks.count else { return "" }
        switch tableColumn!.identifier.rawValue {
        case "Name": return conflictSet.chunks[row].0.name
        case "Activation": return String(format: "%.3f",conflictSet.chunks[row].1)
        default: return "Error"
        }
    }
    
    
    @IBAction func clickInTable(_ sender: NSTableView) {
        guard sender.selectedRow >= 0 && sender.selectedRow < conflictSet.chunks.count else { return }
        selectedRow = sender.selectedRow
        let chunk = conflictSet.chunks[selectedRow!].0
        if let s = conflictSet.chunkTexts[chunk.name] {
            chunkDescriptionTextField.stringValue = s
        } else {
            chunkDescriptionTextField.stringValue = ""
        }
    }

}
