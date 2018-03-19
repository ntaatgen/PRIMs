//
//  Action.swift
//  PRIMs
//
//  Created by Niels Taatgen on 4/28/15.
//  Copyright (c) 2015 Niels Taatgen. All rights reserved.
//

import Foundation


enum NoiseType {
    case none
    case uniform
    case logistic
}

struct ActionInstance {
    var name: String
    var outputString: String
    var meanLatency: Double
    var noiseType: NoiseType = .none
    var noiseValue: Double = 0.0
    init(name: String, meanLatency: Double) {
        self.name = name
        self.meanLatency = meanLatency
        self.outputString = name + "ing"
    }
    func latency() -> Double {
        switch noiseType {
        case .none:
            return meanLatency
        case .logistic:
            return max(0.0, meanLatency + actrNoise(noiseValue))
        case .uniform:
            let rand = Double(Int(arc4random_uniform(100000-2)+1))/100000.0  // value between 0 and 1
            return max(0.0, meanLatency - noiseValue + 2 * noiseValue * rand)
        }
    }
}


class Action {
    unowned let model: Model
    static let defaultPerceptionActionLatencyDefault = 0.2
    /// Default latency for an action when left unspecified
    var defaultPerceptualActionLatency = defaultPerceptionActionLatencyDefault
    /// Dictionary with actions that have a specified latency and possibly noise on that latency
    var actions: [String:ActionInstance] = [:]
    /// Representation of the current visual screen using chunks as a representation
    var visicon = [String:Chunk]()
    
    
    init(model: Model) {
        self.model = model
    }

    func setParametersToDefault() {
         defaultPerceptualActionLatency = Action.defaultPerceptionActionLatencyDefault
    }

    func initTask() {
//        if model.scenario.script == nil {
//            model.scenario.goStart(model)
//            model.buffers["input"] = model.scenario.current(model)
//        }
    }
    
    /**
    Create a new goal chunk using the description in the action, and put it in the first available G slot
    - Parameter chunk: the action chunk
    */
    func createNewGoal(chunk: Chunk) {
        guard let name = chunk.slotValue("slot2")?.description else { return }
        var newGoal = Chunk(s: name, m: model)
        if model.dm.chunks[name] != nil {
            newGoal = model.dm.chunks[name]!
            newGoal.slotvals = [:]
            newGoal.printOrder = []
        }
        newGoal.setSlot("isa", value: "goaltype")
        var index = 3
        while chunk.slotValue("slot\(index)") != nil {
            let attribute = chunk.slotValue("slot\(index)")!.description
            guard let value = chunk.slotValue("slot\(index + 1)")?.description else { return }
            newGoal.setSlot(attribute, value: value)
            index = index + 2
        }
        if model.dm.chunks[name] != nil {
            _ = model.dm.addToDM(chunk: newGoal)
        }
        // now put the new goal in the first available slot
        index = 1
        while model.buffers["goal"]?.slotValue("slot\(index)") != nil {
            index = index + 1
        }
        model.buffers["goal"]!.setSlot("slot\(index)", value: newGoal)
    }
    
    func action() -> Double {
        let actionChunk = model.buffers["action"]!
        var latency = 0.05
        model.buffers["action"] = nil
        let ac = actionChunk.slotvals["slot1"]?.description
        if ac == nil { return 0.0 }
        if ac! == "build-goal" {
            createNewGoal(chunk: actionChunk)
            return 0.2
        }
        let par1 = actionChunk.slotvals["slot2"]?.description
        let par2 = actionChunk.slotvals["slot3"]?.description
        let actionInstance = actions[ac!]
//        let result = model.scenario.doAction(model,action: ac,par1: par1)
        let nothing = ""
//        if result != nil {
//            model.buffers["input"] = result!
//            latency = defaultPerceptualActionLatency
//        }
        if ac! == "wait" {
            if !model.silent {
                model.addToTrace("Waiting (latency = \(latency.string(fractionDigits: 3)))",level: 2)
            }
            latency = 0.05
            if model.scenario.nextEventTime == nil {
            } else {
                latency = max(0, model.scenario.nextEventTime! - model.time)
            }
        } else if actionInstance != nil {
            latency = actionInstance!.latency()
            if !model.silent {
                model.addToTrace("\(actionInstance!.outputString) \(par1 == nil ? nothing : par1!) \(par2 == nil ? nothing : par2!) (latency = \(latency.string(fractionDigits: 3)))", level: 2)
            }
        } else if !model.silent {
            model.addToTrace("\(ac!)-ing \(par1 == nil ? nothing : par1!)-\(par2 == nil ? nothing : par2!)", level: 2)
        }
        model.addToBatchTrace(model.time + latency - model.startTime, type: "action", addToTrace: "\(ac!)-\(par1 == nil ? nothing : par1!)")
            let dl = DataLine(eventType: "action", eventParameter1: ac!, eventParameter2: par1 ?? "void", eventParameter3: par2 ?? "void", inputParameters: model.scenario.inputMappingForTrace,time: model.time + latency - model.startTime)
            model.outputData.append(dl)
        
//        if result != nil {
//            let slot1 = result!.slotvals["slot1"]?.description
//            let slot2 = result!.slotvals["slot2"]?.description
//            let slot3 = result!.slotvals["slot3"]?.description
//            
//            let dl = DataLine(eventType: "perception", eventParameter1: slot1 ?? "void", eventParameter2: slot2 ?? "void", eventParameter3: slot3 ?? "void", inputParameters: model.scenario.inputMappingForTrace, time: model.time + latency - model.startTime)
//            model.outputData.append(dl)
//        }
        return latency
    }
    
    /**
     Do a push on one of the slots in the retrieval (harvest) buffer. One of the chunks in the slots of the retrieval is put into the retrieval buffer, while a parent link is left behind to recover the parent on a pop
     - parameter slot: The slotname of the to be pushed chunk
     - returns: Whether the push was successful
     */
    func push(slot: String) -> Bool {
        if model.buffers["input"] == nil {
            return false
        }
        let oldInput = model.buffers["input"]!
        if let value = oldInput.slotvals[slot] {
            if let chunk = visicon[value.description] {
                if slot == "slot2" {
                    chunk.parent = oldInput.parent // Slot2 is "special": it refers to the next item on the same level, so we copy the parent information
                } else {
                    chunk.parent = oldInput.name
                }
                model.buffers["input"] = chunk
                return true
            } else {
                return false // there is a String or a number in that slot
            }
        } else {
            return false
        }
    }
    
    /** Carry out a "pop" action on the Retrieval harbest buffer: restore the previous element in the tree, assuming it exists.
     - returns: Whether the pop was successful
     */
    func pop() -> Bool {
        if let parent = model.buffers["input"]?.parent {
            model.buffers["input"] = visicon[parent]!
            return true
        } else {
            return false
        }
    }

    
    
}
