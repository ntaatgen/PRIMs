//
//  Model.swift
//  actr
//
//  Created by Niels Taatgen on 3/1/15.
//  Copyright (c) 2015 Niels Taatgen. All rights reserved.
//

import Foundation

class Model {
    var time: Double = 0
    var dm = Declarative()
    lazy var procedural: Procedural = { () -> Procedural in return Procedural(model: self) }()
    var goal: Chunk? = nil
    var buffers: [String:Chunk] = [:]
    var chunkIdCounter = 0
    var running = false
    var trace: String {
        didSet {
            NSNotificationCenter.defaultCenter().postNotificationName("TraceChanged", object: nil)
        }
    }
    var waitingForAction: Bool = false {
        didSet {
            if waitingForAction == true {
                println("Posted Action notification")
                NSNotificationCenter.defaultCenter().postNotificationName("Action", object: nil)
            }
        }
    }
    var modelText: String = ""
    var inputs: [Chunk] = []
    var currentTask: String? = nil
    
    init() {
        trace = ""
    }
    
    func addToTrace(s: String) {
        let timeString = String(format:"%.2f", time)
        println("\(timeString)  " + s)
        trace += "\(timeString)  " + s + "\n"
    }
    
    func clearTrace() {
        trace = ""
    }
    
    
    func step() {
        if currentTask == nil { return }
        if !running {
            buffers = [:]
            procedural.reset()
            let ch = Chunk(s: "goal", m: self)
            ch.setSlot("isa", value: "goal")
            ch.setSlot("slot1", value: "start")
            ch.setSlot("slot2", value: currentTask!)
            buffers["goal"] = ch
            let trial = inputs[Int(arc4random_uniform(UInt32(inputs.count)))]
            buffers["input"] = trial
            running = true
            clearTrace()
        }
        dm.clearFinsts()
        // first retrieve an operator
        var found: Bool = false
        do {
            procedural.lastProduction = nil
            let opInst = procedural.compileOperators ? procedural.findOperatorProduction() : nil
            if opInst == nil {
                let retrievalRQ = Chunk(s: "operator", m: self)
                retrievalRQ.setSlot("isa", value: "operator")
                var (latency,opRetrieved) = dm.retrieve(retrievalRQ)
                if procedural.retrieveOperatorsConditional {
                    var cfs = dm.conflictSet.sorted({ (item1, item2) -> Bool in
                        let (_,u1) = item1
                        let (_,u2) = item2
                        return u1 > u2
                    })
                    var match = false
                    var candidate: Chunk
                    var activation: Double
                    do {
                        (candidate, activation) = cfs.removeAtIndex(0)
                        println("Trying operator \(candidate.name)")
                        let savedBuffers = buffers
                        buffers["operator"] = candidate.copy()
                        let inst = procedural.findMatchingProduction()
                        match = procedural.fireProduction(inst, compile: false)
                        buffers = savedBuffers
                    } while !match && !cfs.isEmpty && cfs[0].1 > dm.retrievalThreshold
                    if match {
                        opRetrieved = candidate
                        latency = dm.latency(activation)
                    } else { opRetrieved = nil
                        latency = dm.latency(dm.retrievalThreshold)
                    }
                }
                time += latency
                if opRetrieved == nil { return }
                addToTrace("Retrieved operator \(opRetrieved!.name)")
                dm.addToFinsts(opRetrieved!)
                buffers["operator"] = opRetrieved!.copy()
                procedural.lastOperator = opRetrieved!
            } else {
                addToTrace("Firing operator production \(opInst!.p.name)")
                procedural.fireProduction(opInst!, compile: true)
                time += 0.05
            }
            let savedBuffers = buffers
            var match: Bool = true
            println("Entering completion loop")
            while match && (buffers["operator"]!.slotvals["condition"] != nil || buffers["operator"]!.slotvals["action"] != nil) {
                let inst = procedural.findMatchingProduction()
                addToTrace("Firing \(inst.p.name)")
                match = procedural.fireProduction(inst, compile: true)
                time += 0.5
            }
            let x = buffers["operator"]
            println("Leaving completion loop: \(x!)")
            if match {
                found = true
            } else {
                buffers = savedBuffers
                buffers["operator"] = nil
            }
        } while !found
        buffers["operator"] = nil
        if let retrievalQuery = buffers["retrievalR"] {
            let (latency, retrieveResult) = dm.retrieve(retrievalQuery)
            time += latency
            if retrieveResult != nil {
                addToTrace("Retrieving \(retrieveResult!.name)")
                buffers["retrievalH"] = retrieveResult!
            } else {
                addToTrace("Retrieval failure")
                let failChunk = Chunk(s: "RetrievalFailure", m: self)
                failChunk.setSlot("slot1", value: "error")
                buffers["retrievalH"] = failChunk
            }
        }
        buffers["retrievalR"] = nil
        if let actionQuery = buffers["action"] {
            addToTrace("Doing action \(actionQuery)")
            buffers["action"] = nil
        }
        if buffers["goal"]!.slotvals["slot1"]!.text()! == "stop" {
            procedural.issueReward(20.0)
            running = false
        }
    }
    
    func run() {
        if currentTask == nil { return }
        if !running { step() }
        while running {
            step()
        }
        
        
    }
    
    func generateNewChunk(s1: String = "chunk") -> Chunk {
        let name = s1 + "\(chunkIdCounter++)"
        let chunk = Chunk(s: name, m: self)
        return chunk
    }
    
    func stringToValue(s: String) -> Value {
        let possibleNumVal = NSNumberFormatter().numberFromString(s)?.doubleValue
        if possibleNumVal != nil {
            return Value.Number(possibleNumVal!)
        }
        if let chunk = self.dm.chunks[s] {
            return Value.Symbol(chunk)
        } else {
            return Value.Text(s)
        }
    }
}