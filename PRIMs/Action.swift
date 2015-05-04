//
//  Action.swift
//  PRIMs
//
//  Created by Niels Taatgen on 4/28/15.
//  Copyright (c) 2015 Niels Taatgen. All rights reserved.
//

import Foundation

class Action {
    let model: Model
    var sayLatency = 0.3
    var subvocalizeLatency = 0.3
    var readLatency = 0.2
    static let nothing = "nothing"
    init(model: Model) {
        self.model = model
    }

    func initTask() {
        switch model.currentTask! {
        case "list-recall":
            stimulusList = ["k","e","d","x"]
            nextTime = model.time + 2.0
            let inputChunk = Chunk(s: "input", m: model)
            inputChunk.setSlot("isa", value: "fact")
            inputChunk.setSlot("slot1", value: "nothing")
            model.buffers["input"] = inputChunk
        default: break
        }
    }
    
    func action() -> Double {
        let actionChunk = model.buffers["action"]!
        var latency = 0.05
        model.buffers["action"] = nil
        let ac = actionChunk.slotvals["slot1"]?.description
        let par1 = actionChunk.slotvals["slot2"]?.description
        switch model.currentTask! {
        case "list-recall":
            model.buffers["input"] = listRecall(actionChunk)
        default: break
        }
        if ac != nil {
            switch ac! {
            case "say":
                model.addToTrace("Saying \(par1 == nil ? Action.nothing : par1!)")
                latency = sayLatency
            case "subvocalize":
                model.addToTrace("Subvocalizing \(par1 == nil ? Action.nothing : par1!)")
                latency = subvocalizeLatency
            case "read":
                model.addToTrace("Reading")
                latency = nextTime - model.time
            case "wait":
                model.addToTrace("Waiting")
                latency = max(0, nextTime - model.time)
            default: model.addToTrace("\(ac!)-ing \(par1 == nil ? Action.nothing : par1!)")
            }
        }
        return latency
    }
    
    var stimulusList: [String] = ["k","e","d","x"]
    var nextTime: Double = 2.0 {
        didSet { println("Next Stimulus time \(nextTime)")
        }
    }
    
    func listRecall(action: Chunk?) -> Chunk {
        let inputChunk = Chunk(s: "input", m: model)
        inputChunk.setSlot("isa", value: "fact")
        if action == nil || action?.slotValue("slot1")!.description == "wait" && !stimulusList.isEmpty {
            inputChunk.setSlot("slot1", value: "letter")
            inputChunk.setSlot("slot2", value: stimulusList.removeAtIndex(0))
            nextTime += 2.0
        } else if action?.slotValue("slot1")!.description == "read" {
            inputChunk.setSlot("slot1", value: "nothing")
        } else if stimulusList.isEmpty {
            inputChunk.setSlot("slot1", value: "report")
        }
        return inputChunk
    }
    
}