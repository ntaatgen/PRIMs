//
//  Action.swift
//  PRIMs
//
//  Created by Niels Taatgen on 4/28/15.
//  Copyright (c) 2015 Niels Taatgen. All rights reserved.
//

import Foundation


enum NoiseType {
    case None
    case Uniform
    case Logistic
}

struct ActionInstance {
    var name: String
    var outputString: String
    var meanLatency: Double
    var noiseType: NoiseType = .None
    var noiseValue: Double = 0.0
    init(name: String, meanLatency: Double) {
        self.name = name
        self.meanLatency = meanLatency
        self.outputString = name + "ing"
    }
    func latency() -> Double {
        switch noiseType {
        case .None:
            return meanLatency
        case .Logistic:
            return max(0.0, meanLatency + actrNoise(noiseValue))
        case .Uniform:
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
    
    
    init(model: Model) {
        self.model = model
    }
    
    deinit {
        print("Action is deinitialized")
    }
    
    func setParametersToDefault() {
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
        if ac == nil { return 0.0 }
        let par1 = actionChunk.slotvals["slot2"]?.description
        let par2 = actionChunk.slotvals["slot3"]?.description
        let actionInstance = actions[ac!]
        let result = model.scenario.doAction(model,action: ac,par1: par1)
        let nothing = ""
        if result != nil {
            model.buffers["input"] = result!
            latency = defaultPerceptualActionLatency
        }
        if ac! == "wait" {
            model.addToTrace("Waiting (latency = \(latency))",level: 2)
            latency = 0.05
            if model.scenario.nextEventTime == nil {
            } else {
                latency = max(0, model.scenario.nextEventTime! - model.time)
            }
        } else if actionInstance != nil {
            latency = actionInstance!.latency()
            model.addToTrace("\(actionInstance!.outputString) \(par1 == nil ? nothing : par1!) \(par2 == nil ? nothing : par2!) (latency = \(latency))", level: 2)
        } else {
            model.addToTrace("\(ac!)-ing \(par1 == nil ? nothing : par1!) \(par2 == nil ? nothing : par2!) (latency = \(latency))", level: 2)

        }
            let dl = DataLine(eventType: "action", eventParameter1: ac!, eventParameter2: par1 ?? "void", eventParameter3: par2 ?? "void", inputParameters: model.scenario.inputMappingForTrace,time: model.time + latency - model.startTime)
            model.outputData.append(dl)
        
        if result != nil {
            let slot1 = result!.slotvals["slot1"]?.description
            let slot2 = result!.slotvals["slot2"]?.description
            let slot3 = result!.slotvals["slot3"]?.description
            
            let dl = DataLine(eventType: "perception", eventParameter1: slot1 ?? "void", eventParameter2: slot2 ?? "void", eventParameter3: slot3 ?? "void", inputParameters: model.scenario.inputMappingForTrace, time: model.time + latency - model.startTime)
            model.outputData.append(dl)
        }
        return latency
    }
    
    
}