//
//  Operator.swift
//  PRIMs
//
//  Created by Niels Taatgen on 7/28/15.
//  Copyright (c) 2015 Niels Taatgen. All rights reserved.
//

import Foundation

/**
    The Operator class contains many of the functions that deal with operators. Most of these still have to be migrated from Model.swift
*/
class Operator {
    /// This Array has all the operators with arrays of their conditions and actions. We use this to find the optimal ovelap when defining new operators
    var operatorCA: [(String,[String],[String])] = []
    let model: Model
    
    init(model: Model) {
        self.model = model
    }

    /**
    Reset the operator object
    */
    func reset() {
        operatorCA = []
    }
    
    
    /**
    Determine the amount of overlap between two lists of PRIMs
    */
    func determineOverlap(oldList: [String], newList: [String]) -> Int {
        var count = 0
        for prim in oldList {
            if !newList.contains(prim) {
                return count
            }
            count++
        }
        return count
    }
    
    /**
    Construct a string of PRIMs from the best matching operators
    */
    func constructList(template: [String], source: [String], overlap: Int) -> (String, [String]) {
        var primList = ""
        var primArray = [String]()
        if overlap > 0 {
            for i in 0..<overlap {
                primList =  (primList == "" ? template[i] : template[i] + ";" ) + primList
                primArray.append(template[i])
            }
        }
        for prim in source {
            if !primArray.contains(prim) {
                primList = (primList == "" ? prim : prim + ";" ) + primList
                primArray.append(prim)
            }
        }
        return (primList, primArray)
    }
    
    
    /**
    Add conditions and actions to an operator while trying to optimize the order of the PRIMs to maximize overlap with existing operators 
    */
    func addOperator(op: Chunk, conditions: [String], actions: [String]) {
        var bestConditionMatch: [String] = []
        var bestConditionNumber: Int = -1
        var bestConditionActivation: Double = -1000
        var bestActionMatch: [String] = []
        var bestActionNumber: Int = -1
        var bestActionActivation: Double = -1000
        for (chunkName, chunkConditions, chunkActions) in operatorCA {
            if let chunkActivation = model.dm.chunks[chunkName]?.baseLevelActivation() {
                let conditionOverlap = determineOverlap(chunkConditions, newList: conditions)
                if (conditionOverlap > bestConditionNumber) || (conditionOverlap == bestConditionNumber && chunkActivation > bestConditionActivation) {
                    bestConditionMatch = chunkConditions
                    bestConditionNumber = conditionOverlap
                    bestConditionActivation = chunkActivation
                }
                let actionOverlap = determineOverlap(chunkActions, newList: actions)
                if (actionOverlap > bestActionNumber) || (actionOverlap == bestActionNumber && chunkActivation > bestActionActivation) {
                    bestActionMatch = chunkActions
                    bestActionNumber = actionOverlap
                    bestActionActivation = chunkActivation
                }
            }
        }
        let (conditionString, conditionList) = constructList(bestConditionMatch, source: conditions, overlap: bestConditionNumber)
        let (actionString, actionList) = constructList(bestActionMatch, source: actions, overlap: bestActionNumber)
        op.setSlot("condition", value: conditionString)
        op.setSlot("action", value: actionString)
        operatorCA.append((op.name, conditionList, actionList))
    }
    
    
    /// List of chosen operators with time
    var previousOperators: [(Chunk,Double)] = []
    
    /**
    Update the Sji's between the current goal(s?) and the operators that have fired. Restrict to updating the goal in G1 for now.
    
    - parameter payoff: The payoff that will be distributed
    */
    func updateOperatorSjis(payoff: Double) {
        if !model.dm.goalOperatorLearning || model.reward == 0.0 { return } // only do this when switched on
        let goalChunk = model.formerBuffers["goal"]?.slotvals["slot1"]?.chunk() // take formerBuffers goal, because goal may have been replace by stop or nil
        if goalChunk == nil { return }
        for (operatorChunk,operatorTime) in previousOperators {
            let opReward = model.dm.defaultOperatorAssoc * (payoff - (model.time - operatorTime)) / model.reward
            if operatorChunk.assocs[goalChunk!.name] == nil {
                operatorChunk.assocs[goalChunk!.name] = (0.0, 0)
            }
            operatorChunk.assocs[goalChunk!.name]!.0 += model.dm.beta * (opReward - operatorChunk.assocs[goalChunk!.name]!.0)
            operatorChunk.assocs[goalChunk!.name]!.1++
            operatorChunk.addReference() // Also increase baselevel activation of the operator
            model.addToTrace("Updating assoc between \(goalChunk!.name) and \(operatorChunk.name) to \(operatorChunk.assocs[goalChunk!.name]!)")
        }
    }
    
    
    /**
    This function finds an operator. It can do this in several ways depending on the settings
    of the parameters compileOperators and retrieveOperatorsConditional.
    If retrieveOperatorsConditional is true, an operator is retrieved that is checked by the currently
    available productions. If successful, the operator is placed in the operator buffer.
    CHANGE: We now always assume retrieveOperatorsConditional is true
    
    - returns: Whether an operator was successfully found
    */
    func findOperatorOrOperatorProduction() -> Bool {
        let retrievalRQ = Chunk(s: "operator", m: model)
        retrievalRQ.setSlot("isa", value: "operator")
        var (latency,opRetrieved) = model.dm.retrieve(retrievalRQ)
//        if model.procedural.retrieveOperatorsConditional {
            var cfs = model.dm.conflictSet.sort({ (item1, item2) -> Bool in
                let (_,u1) = item1
                let (_,u2) = item2
                return u1 > u2
            })
            if model.stepping {
                model.addToTrace("Conflict Set")
                for (chunk,activation) in cfs {
                    model.addToTrace("  \(chunk.name) A = \(activation)")
                }
            }
            var match = false
            var candidate: Chunk
            var activation: Double
            repeat {
                (candidate, activation) = cfs.removeAtIndex(0)
                let savedBuffers = model.buffers
                model.buffers["operator"] = candidate.copy()
                let inst = model.procedural.findMatchingProduction()
                match = model.procedural.fireProduction(inst, compile: false)
                if match && candidate.spreadingActivation() <= 0.0 && model.buffers["operator"]?.slotValue("condition") != nil {
                    match = false
                    model.addToTrace("   Rejected operator \(candidate.name) because it has no associations and no production that tests all conditions")
                }
                model.buffers = savedBuffers
            } while !match && !cfs.isEmpty && cfs[0].1 > model.dm.retrievalThreshold
            if match {
                opRetrieved = candidate
                latency = model.dm.latency(activation)
            } else {
                opRetrieved = nil
                latency = model.dm.latency(model.dm.retrievalThreshold)
            }
//        }
        model.time += latency
        if opRetrieved == nil { return false }
        if model.dm.goalOperatorLearning {
            let item = (opRetrieved!, model.time - latency)
            previousOperators.append(item)
        }
        model.addToTrace("*** Retrieved operator \(opRetrieved!.name) with spread \(opRetrieved!.spreadingActivation())")
        model.dm.addToFinsts(opRetrieved!)
        model.buffers["goal"]!.setSlot("last-operator", value: opRetrieved!)
        model.buffers["operator"] = opRetrieved!.copy()
        model.formerBuffers["operator"] = opRetrieved!
        
        
        return true
    }
    
    
    /**
    This function carries out productions for the current operator until it has a PRIM that fails, in
    which case it returns false, or until all the conditions of the operator have been tested and
    all actions have been carried out.
    */
    func carryOutProductionsUntilOperatorDone() -> Bool {
        var match: Bool = true
        var first: Bool = true
        while match && (model.buffers["operator"]?.slotvals["condition"] != nil || model.buffers["operator"]?.slotvals["action"] != nil) {
            let inst = model.procedural.findMatchingProduction()
            var pname = inst.p.name
            if pname.hasPrefix("t") {
                pname = String(pname.characters.dropFirst())
            }
            model.addToTrace("Firing \(pname)")
            match = model.procedural.fireProduction(inst, compile: true)
            if first {
                model.time += model.procedural.productionActionLatency
                first = false
            } else {
                model.time += model.procedural.productionAndPrimLatency
            }
        }
        return match
    }
    
    
}