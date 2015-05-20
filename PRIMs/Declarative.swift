//
//  Declarative.swift
//  actr
//
//  Created by Niels Taatgen on 3/1/15.
//  Copyright (c) 2015 Niels Taatgen. All rights reserved.
//

import Foundation

class Declarative  {
    weak var model: Model!
    var baseLevelDecay: Double = 0.5
    var optimizedLearning = true
    var maximumAssociativeStrength: Double = 3
    var goalActivation: Double = 3 // W parameter
    var retrievalThreshold: Double = -2
    var activationNoise: Double? = 0.25
    var defaultOperatorAssoc: Double = 2.0
    var chunks = [String:Chunk]()
    var misMatchPenalty: Double = 5
    var conflictSet: [(Chunk,Double)] = []
    var finsts: [String] = []
    
    var latencyFactor = 0.2
    
    var retrieveBusy = false
    var retrieveError = false
    var retrievaltoDM = false
    
    init(model: Model) {
        self.model = model
    }
    
    func duplicateChunk(chunk: Chunk) -> Chunk? {
        /* Return duplicate chunk if there is one, else nil */
        for (_,c1) in chunks {
            if c1 == chunk { return c1 }
        }
        return nil
    }
    
    func retrievalState(slot: String, value: String) -> Bool {
        switch (slot,value) {
        case ("state","busy"): return retrieveBusy
        case ("state","error"): return retrieveError
        default: return false
        }
    }
    
    func clearFinsts() {
        finsts = []
    }
    
    func addToFinsts(c: Chunk) {
        finsts.append(c.name)
    }
    
    func addToDMOrStrengthen(chunk: Chunk) -> Chunk {
        if let dupChunk = duplicateChunk(chunk) {
            dupChunk.addReference()
            dupChunk.mergeAssocs(chunk)
                        return dupChunk
        } else {
            chunk.startTime()
            chunks[chunk.name] = chunk
            for (_,val) in chunk.slotvals {
                switch val {
                case .Symbol(let refChunk):
                    refChunk.fan++
                default: break
                }
            }
        return chunk
        }
    }
    
    func addToDM(chunk: Chunk) {
        if let dupChunk = duplicateChunk(chunk) {
            dupChunk.addReference()
            dupChunk.mergeAssocs(chunk)
//            return dupChunk
        } else {
            chunk.startTime()
            chunks[chunk.name] = chunk
            for (_,val) in chunk.slotvals {
                switch val {
                case .Symbol(let refChunk):
                    refChunk.fan++
                default: break
                }
            }
//            return chunk
        }
    }
    
    func latency(activation: Double) -> Double {
        return latencyFactor * exp(-activation)
    }
    
    func retrieve(chunk: Chunk) -> (Double, Chunk?) {
        retrieveError = false
        var bestMatch: Chunk? = nil
        var bestActivation: Double = retrievalThreshold
        conflictSet = []
        chunkloop: for (_,ch1) in chunks {
            if !contains(finsts, ch1.name) {
                for (slot,value) in chunk.slotvals {
                    if let val1 = ch1.slotvals[slot] {
                        if !val1.isEqual(value) {
                            continue chunkloop }
                    } else { continue chunkloop }
                }
                conflictSet.append((ch1,ch1.activation()))
//                println("Activation of \(ch1.name) is \(ch1.activation())")
                if ch1.activation() > bestActivation {
                    bestActivation = ch1.activation()
                    bestMatch = ch1
                }
            }
        }
        if bestActivation > retrievalThreshold {
            return (latency(bestActivation) , bestMatch)
        } else {
            retrieveError = true
            return (latency(retrievalThreshold), nil)
        }
        
    }
    

    
    func partialRetrieve(chunk: Chunk, mismatchFunction: (x: Value, y: Value) -> Double? ) -> Chunk? {
        var bestMatch: Chunk? = nil
        var bestActivation: Double = retrievalThreshold
        conflictSet = []
        chunkloop: for (_,ch1) in chunks {
            var mismatch = 0.0
            for (slot,value) in chunk.slotvals {
                if let val1 = ch1.slotvals[slot] {
                    if !val1.isEqual(value) {
                        let slotmismatch = mismatchFunction(x: val1, y: value)
                        if slotmismatch != nil {
                            mismatch += slotmismatch!
                        } else
                        {
                            continue chunkloop
                        }
                    }
                } else { continue chunkloop }
            }
//            println("Candidate: \(ch1) with activation \(ch1.activation() + mismatch)")
  			let activation = ch1.activation() + mismatch * misMatchPenalty
            conflictSet.append((ch1,activation))
            if activation > bestActivation {
                bestActivation = activation
                bestMatch = ch1
            }        
            }
        return bestMatch
    }

    func action() -> Double {
        let retrievalQuery = model.buffers["retrievalR"]!
        let (latency, retrieveResult) = retrieve(retrievalQuery)
        
        if retrieveResult != nil {
            model.addToTrace("Retrieving \(retrieveResult!.name)")
            model.buffers["retrievalH"] = retrieveResult!
        } else {
            model.addToTrace("Retrieval failure")
            let failChunk = Chunk(s: "RetrievalFailure", m: model)
            failChunk.setSlot("slot1", value: "error")
            model.buffers["retrievalH"] = failChunk
        }
        
        model.buffers["retrievalR"] = nil
        return latency
    }
    
}