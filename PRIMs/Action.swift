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
    static let sayLatencyDefault = 0.3
    static let subvocalizeLatencyDefault = 0.3
    static let readLatencyDefault = 0.2
    static let defaultPerceptionActionLatencyDefault = 0.2
    
    var sayLatency = sayLatencyDefault
    var subvocalizeLatency = subvocalizeLatencyDefault
    var readLatency = readLatencyDefault
    var defaultPerceptualActionLatency = defaultPerceptionActionLatencyDefault
    static let nothing = "nothing"
    
    
    init(model: Model) {
        self.model = model
    }
    
    func setParametersToDefault() {
         sayLatency = Action.sayLatencyDefault
         subvocalizeLatency = Action.subvocalizeLatencyDefault
         readLatency = Action.readLatencyDefault
         defaultPerceptualActionLatency = Action.defaultPerceptionActionLatencyDefault
    }

    func initTask() {
        
        model.scenario.goStart(model)
        model.buffers["input"] = model.scenario.current(model)
    }
    
    
    func action() -> Double {
        let actionChunk = model.buffers["action"]!
        var latency = 0.05
        model.buffers["action"] = nil
        let ac = actionChunk.slotvals["slot1"]?.description
        let par1 = actionChunk.slotvals["slot2"]?.description
        
        let result = model.scenario.doAction(model,action: ac,par1: par1)
        if result != nil {
            model.buffers["input"] = result!
            latency = defaultPerceptualActionLatency
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
                latency = defaultPerceptualActionLatency
            case "wait":
                model.addToTrace("Waiting")
                if model.scenario.nextEventTime == nil {
                    latency = 0.05
                } else {
                    latency = max(0, model.scenario.nextEventTime! - model.time)
                }
                    
            default: model.addToTrace("\(ac!)-ing \(par1 == nil ? Action.nothing : par1!)")
            }
            let dl = DataLine(eventType: "action", eventParameter1: ac!, eventParameter2: par1 ?? "void", eventParameter3: "void", time: model.time + latency - model.startTime)
            model.outputData.append(dl)
        }
        if result != nil {
            let slot1 = result!.slotvals["slot1"]?.description
            let slot2 = result!.slotvals["slot2"]?.description
            let slot3 = result!.slotvals["slot3"]?.description
            
            let dl = DataLine(eventType: "perception", eventParameter1: slot1 ?? "void", eventParameter2: slot2 ?? "void", eventParameter3: slot3 ?? "void", time: model.time + latency - model.startTime)
            model.outputData.append(dl)
        }
        return latency
    }
    
    
}