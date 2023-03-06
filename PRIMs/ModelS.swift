//
//  ModelS.swift
//  PRIMs
//
//  Created by Niels Taatgen on 3/2/23.
//

import Foundation


struct ModelS {
    internal var model = Model(silent: false)
    /// The trace from the model
    var traceText: String = ""
    /// The model code
    var modelText: String = ""
    /// Part of the contents of DM that can needs to be displayed in the interface
    var dmContent: [PublicChunk] = []
    /// What are the contents of the buffers?
    var bufferContent: [String:Chunk] = [:]
    /// What is the level of detail of the trace
    var formerBufferContent: [String:Chunk] = [:]
    var traceLevel: Int = 1
    
    var modelResults: [ModelData] = []
    
    var currentModelURL: URL? {
        if model.currentTaskIndex != nil {
            return model.tasks[model.currentTaskIndex!].filename
        } else {
            return nil
        }
    }
    
    var tasks: [Task] = []
    
    var currentTask: String?
    
    /// Run the model
    mutating func run() {
        model.run()
        update()
    }
    
    mutating func runMultiple(_ runs: Int) {
        model.tracing = false
        for _ in 0..<(runs-1) {
            model.run()
        }
        model.tracing = true
        model.run()
        update()
    }

    mutating func step() {
        model.step()
        update()
    }
    
    /// Reset the model and the game
    mutating func reset(_ taskNumber: Int?) {
        model.reset(taskNumber)
    }
    
    mutating func clear() {
        model = Model(silent: false)
    }
    
    mutating func loadModel(filePath: URL) {
        if !model.loadModelWithString(filePath) {
            update()
            return
        }
        update()
    }
    
    func formatBuffer(_ bufferName: String, bufferChunk: Chunk?, bufferAbbreviation: String, showSlot0: Bool = true) -> String {
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
        return rest
    }
        
    
    func formatOperator(_ chunk: Chunk?) -> String {
        var rest = chunk == nil ? "" : chunk!.name
        rest += "\n"
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
        rest.append(formatBuffer("", bufferChunk: chunk, bufferAbbreviation: "C", showSlot0: false))
        return rest
    }
    
    var operatorString: String {
        formatOperator(formerBufferContent["operator"])
    }
    
    var formerGoal: String {
        formatBuffer("Goal", bufferChunk: formerBufferContent["goal"], bufferAbbreviation: "G")
    }
    
    var newGoal: String {
        if formerBufferContent["goal"] != bufferContent["goal"] {
            return formatBuffer("Goal", bufferChunk: bufferContent["goal"], bufferAbbreviation: "G") }
        else {
            return ""
        }
    }
    
    var formerInput: String {
        formatBuffer("Input", bufferChunk: formerBufferContent["input"], bufferAbbreviation: "V", showSlot0: false)
    }
    
    var newInput: String {
        if formerBufferContent["input"] != bufferContent["input"] {
            return formatBuffer("input", bufferChunk: bufferContent["input"], bufferAbbreviation: "V", showSlot0: false)
        } else {
            return ""
        }
    }
    
    var formerRetrievalHarvest: String {
        formatBuffer("Retrieval hv.", bufferChunk: formerBufferContent["retrievalH"], bufferAbbreviation: "RT")
    }
    
    var retrievalRequest: String {
        formatBuffer("Retrieval rq.", bufferChunk: formerBufferContent["retrievalR"], bufferAbbreviation: "RT")

    }
    
    var newRetrievalHarvest: String {
        if formerBufferContent["retrievalH"] != bufferContent["retrievalH"] {
            return formatBuffer("Retrieval hv.", bufferChunk: bufferContent["retrievalH"], bufferAbbreviation: "RT")
        } else {
            return ""
        }
    }
    
    var formerImaginal: String {
        formatBuffer("Imaginal", bufferChunk: formerBufferContent["imaginal"], bufferAbbreviation: "WM")
    }
    
    var newImaginal: String {
        if formerBufferContent["imaginal"] != bufferContent["imaginal"] {
            return formatBuffer("Imaginal", bufferChunk: bufferContent["imaginal"], bufferAbbreviation: "WM")            
        } else {
            return ""
        }
    }
    
    var action: String {
        formatBuffer("action", bufferChunk: formerBufferContent["action"], bufferAbbreviation: "AC", showSlot0: false)
    }
    
    mutating func setCurrentTask(task: Task) {
        for i in 0..<tasks.count {
            if tasks[i].id == task.id {
                model.loadOrReloadTask(i)
                update()
                break
            }
        }
    }
    /// Update the representation of the model in the struct. If the struct changes,
    /// the View is automatically updated, but this does not work for classes.
    mutating func update() {
        self.traceText = model.getTrace(traceLevel)
        self.modelText = model.modelText
        dmContent = []
        var count = 0
        for (_,chunk) in model.dm.chunks {
            var slots: [(slot: String,val: String)] = []
            for slot in chunk.printOrder {
                if let val = chunk.slotvals[slot] {
                    slots.append((slot:slot, val:val.description))
                }
            }
            dmContent.append(PublicChunk(name: chunk.name, slots: slots, activation: chunk.activation(),id: count))
            count += 1
        }
        modelResults = []
        count = 0
        if  model.modelResults.count > 0 {
            for i in 0..<model.modelResults.count {
                for (x,y) in model.modelResults[i] {
                    modelResults.append(ModelData(id: count, task: model.tasks[model.resultTaskNumber[i]].name, x: x, y: y))
                    count += 1
                }
            }
        }
        bufferContent = model.buffers
        formerBufferContent = model.formerBuffers
        tasks = model.tasks
        currentTask = model.currentTask
        dmContent.sort { $0.activation > $1.activation }
    }
    
    // MARK: - Graph part

    var graph: FruchtermanReingold?
    
    
    

    
}

struct ModelData: Identifiable {
    var id: Int
    var task: String
    var x: Double
    var y: Double
}
