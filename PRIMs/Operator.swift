//
//  Operator.swift
//  PRIMs
//
//  Created by Niels Taatgen on 7/28/15.
//  Copyright (c) 2015 Niels Taatgen. All rights reserved.
//

import Foundation

/**
 struct to store operators in an easier to use format than Chunks
 */
struct Op {
    /// An array of constants that are normally stored in slot1..n of the chunk
    var constants: [String] = []
    /// An array with the conditions. Each condition is a 5-tuple the 5 components of a PRIM
    var conditions: [(lhsBuffer: String, lhsSlot: Int, rhsBuffer: String, rhsSlot: Int, op: String)] = []
    /// An array with the actions. Each action is a 5-tuple with the 5 components of a PRIM
    var actions: [(lhsBuffer: String, lhsSlot: Int, rhsBuffer: String, rhsSlot: Int, op: String)] = []
    /// Name of the operator
    var name: String
    
    init(name: String) {
        self.name = name
    }
    
    init(chunk: Chunk) {
        let bufferMapping = ["input":"V", "imaginal": "WM", "operator": "C", "action": "AC", "retrievalH" : "RT", "retrievalR" : "RT", "temporal" : "T", "goal" : "G", "constants": "GC" ]
        name = chunk.name
        // This already gives us almost all we need, but we need to do a bit more work on it
        let opConditions = chunk.slotvals["condition"]!.description.components(separatedBy: ";").map(parseName)
        for (lbuf, lslot, cOP, rbuf, rslot, _) in opConditions {
            let lslotNum = (lslot == nil || !lslot!.hasPrefix("slot")) ? 0 : Int(String(lslot![lslot!.index(lslot!.startIndex, offsetBy: 4)])) ?? 0
            let rslotNum = (rslot == nil || !rslot!.hasPrefix("slot")) ? 0 : Int(String(rslot![rslot!.index(rslot!.startIndex, offsetBy: 4)])) ?? 0
            conditions.append((lhsBuffer: lbuf == nil ? "" : bufferMapping[lbuf!]!, lhsSlot: lslotNum, rhsBuffer: rbuf == nil ? "" : bufferMapping[rbuf!]!, rhsSlot: rslotNum, op: cOP))
        }
        // Same for actions
        if let actionString = chunk.slotvals["action"]?.description  {
            let opActions = actionString.components(separatedBy: ";").map(parseName)
            for (lbuf, lslot, cOP, rbuf, rslot, _) in opActions {
                let lslotNum = (lslot == nil || !lslot!.hasPrefix("slot")) ? 0 : Int(String(lslot![lslot!.index(lslot!.startIndex, offsetBy: 4)])) ?? 0
                let rslotNum = (rslot == nil || !rslot!.hasPrefix("slot")) ? 0 : Int(String(rslot![rslot!.index(rslot!.startIndex, offsetBy: 4)])) ?? 0
                actions.append((lhsBuffer: lbuf == nil ? "" : bufferMapping[lbuf!]!, lhsSlot: lslotNum, rhsBuffer: rbuf == nil ? "" : bufferMapping[rbuf!]!, rhsSlot: rslotNum, op: cOP))
            }
        }
        var i = 1
        while let c = chunk.slotvals["slot\(i)"] {
            constants.append(c.description)
            i += 1
        }
    }
    
    func buildChunk(model: Model) -> Chunk {
        let chunk = Chunk(s: name, m: model)
        chunk.setSlot("isa", value: "operator")
        var i = 1
        for value in constants {
            chunk.setSlot("slot\(i)", value: value)
            i += 1
        }
        var conditionString = ""
        var itemList: [String] = []
        for (lbuf, lslot, rbuf, rslot, op) in conditions {
            
            let lhs = lslot > 0 ? lbuf + String(lslot) : op != ">>" && op != "<<" ? "nil" : lbuf
            let rhs = rslot > 0 ? rbuf + String(rslot) : op != ">>" && op != "<<" ? "nil" : rbuf

            let prim = lhs + op + rhs
            if !itemList.contains(prim) {
                itemList.append(prim)
                if conditionString == "" {
                    conditionString = prim
                } else {
                    conditionString += ";" + prim
                }
            }
        }
        chunk.setSlot("condition", value: conditionString)
        var actionString = ""
        itemList = []
        for (lbuf, lslot, rbuf, rslot, op) in actions {
            let lhs = lslot > 0 ? lbuf + String(lslot) : op != ">>" && op != "<<" ? "nil" : lbuf
            let rhs = rslot > 0 ? rbuf + String(rslot) : op != ">>" && op != "<<" ? "nil" : rbuf
            let prim = lhs + op + rhs
            if !itemList.contains(prim) {
                itemList.append(prim)
                if actionString == "" {
                    actionString = prim
                } else {
                    actionString += ";" + prim
                }
            }
        }
        if actionString != "" {
            chunk.setSlot("action", value: actionString)
        }
        chunk.fixedActivation = model.dm.defaultActivation
        return chunk
        
    }
}

/**
    The Operator class contains many of the functions that deal with operators.
*/
class Operator {

    unowned let model: Model
    /// List of chosen operators with time and context. Context is use to support learning between all context chunks and operators
    var previousOperators: [(Chunk,Double,[(String, String, Chunk)])] = []

    init(model: Model) {
        self.model = model
    }

    
    /**
    Reset the operator object
    */
    func reset() {
    }
    
    
    /**
    Determine the amount of overlap between two lists of PRIMs
    */
    func determineOverlap(_ oldList: [String], newList: [String]) -> Int {
        var count = 0
        for prim in oldList {
            if !newList.contains(prim) {
                return count
            }
            count += 1
        }
        return count
    }
    
    /**
    Construct a string of PRIMs from the best matching operators
    */
    func constructList(_ template: [String], source: [String], overlap: Int) -> (String, [String]) {
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
    /*
    func addOperator(_ op: Chunk, conditions: [String], actions: [String]) {
        var bestConditionMatch: [String] = []
        var bestConditionNumber: Int = -1
        var bestConditionActivation: Double = -1000
        var bestActionMatch: [String] = []
        var bestActionNumber: Int = -1
        var bestActionActivation: Double = -1000
        for (chunkName, chunkConditions, chunkActions) in model.dm.operatorCA {
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
        model.dm.operatorCA.append((op.name, conditionList, actionList))
    }
    */
    
    
    /**
    Compile the sequence of operators in the list of previous operators
    */
    func compileAll() {
        guard model.operatorLearning else { return }
        guard previousOperators.count > 1 else { return }
        for i in 0..<previousOperators.count - 1 {
            if let newChunk = compileOperators(op1: previousOperators[i].0, op2: previousOperators[i + 1].0) {
                let chunk2 = model.dm.addToDM(chunk: newChunk)
                chunk2.fixedActivation = previousOperators[i].0.fixedActivation
                print("Setting activation of \(chunk2.name) to \(chunk2.fixedActivation ?? -999)")
                previousOperators.append((chunk2, previousOperators[i].1, previousOperators[i].2)) // add it to previous operators so it will also receive a reward
                model.addToTrace("Adding or strengtening operator \(chunk2.name)", level: 5)
                print(chunk2)
            }
        }
    }
    
    func updateOperatorSjis(_ payoff: Double) {
        defer {
            previousOperators = [] // Once we're done clear the previous operators
        }
        guard (model.dm.goalOperatorLearning || model.dm.interOperatorLearning || model.dm.contextOperatorLearning) && model.reward != 0.0  else { return }
        let goalChunk = model.formerBuffers["goal"] // take formerBuffers goal, because goal may have been replaced by stop or nil
        guard goalChunk != nil else { return }
        var goalChunks = Set<Chunk>()
        var index = 1
        while let nextChunk = goalChunk!.slotvals["slot\(index)"] {
            if let isChunk = nextChunk.chunk() {
                goalChunks.insert(isChunk)
            }
            index += 1
        }
        guard goalChunks != [] else { return }
        var prevOperatorChunk: Chunk? = nil
        for (operatorChunk,operatorTime,context) in previousOperators {
            let goalOpReward = model.dm.defaultOperatorAssoc * (payoff - (model.time - operatorTime)) / model.reward
            let interOpReward = model.dm.defaultInterOperatorAssoc * (payoff - (model.time - operatorTime)) / model.reward
            if model.dm.contextOperatorLearning {
                for (bufferName, slotName, chunk) in context {
                    let triplet = bufferName + "%" + slotName + "%" + chunk.name
                    if operatorChunk.assocs[triplet] == nil {
                        operatorChunk.assocs[triplet] = (0.0, 0)
                    }
                    operatorChunk.assocs[triplet]!.0 += model.dm.beta * (goalOpReward - operatorChunk.assocs[triplet]!.0)
                    operatorChunk.assocs[triplet]!.1 += 1
                    if goalOpReward > 0 && model.dm.operatorBaselevelLearning {
                        operatorChunk.addReference() // Also increase baselevel activation of the operator
                    }
                    if !model.silent {
                        model.addToTrace("Updating assoc between \(triplet) and \(operatorChunk.name) to \(operatorChunk.assocs[triplet]!.0.string(fractionDigits: 3))", level: 5)
                    }
                }
            }
            if model.dm.goalOperatorLearning {
                for goal in goalChunks {
                    if operatorChunk.assocs[goal.name] == nil {
                        operatorChunk.assocs[goal.name] = (0.0, 0)
                    }
                    operatorChunk.assocs[goal.name]!.0 += model.dm.beta * (goalOpReward - operatorChunk.assocs[goal.name]!.0)
                    operatorChunk.assocs[goal.name]!.1 += 1
                    if goalOpReward > 0 && model.dm.operatorBaselevelLearning {
                        operatorChunk.addReference() // Also increase baselevel activation of the operator
                    }
                    if !model.silent {
                        model.addToTrace("Updating assoc between \(goal.name) and \(operatorChunk.name) to \(operatorChunk.assocs[goal.name]!.0.string(fractionDigits: 3))", level: 5)
                    }                }
            }
            if model.dm.interOperatorLearning {
                if prevOperatorChunk == nil {
                    prevOperatorChunk = operatorChunk
                } else {
                    if operatorChunk.assocs[prevOperatorChunk!.name] == nil {
                        operatorChunk.assocs[prevOperatorChunk!.name] = (0.0, 0)
                    }
                    operatorChunk.assocs[prevOperatorChunk!.name]!.0 += model.dm.beta * (interOpReward - operatorChunk.assocs[prevOperatorChunk!.name]!.0)
                    operatorChunk.assocs[prevOperatorChunk!.name]!.1 += 1
                    if !model.silent {
                        model.addToTrace("Updating assoc between \(prevOperatorChunk!.name) and \(operatorChunk.name) to \(operatorChunk.assocs[prevOperatorChunk!.name]!.0.string(fractionDigits: 3))", level: 5)
                    }
                    prevOperatorChunk = operatorChunk
                }

            }
        }
    }

    
     
    /**
    Function that checks whether the operator matches the current roles in the goals. If it does, it also returns an operator with the appropriate substitution.
     - parameter op: The candidate operator
     - returns: nil if there is no match, otherwise the operator with the appropriate substitution
    */
    func checkOperatorGoalMatch(op: Chunk) -> Chunk? {
        guard let goalChunk = model.buffers["goal"] else { return nil }
        let opCopy = op.copyChunk()
        var referenceList: [String:Value] = [:]
        for (_,value) in goalChunk.slotvals {  // Go through all the goals in the goal buffer
//            print("Value is \(value.description)")
            if let chunk = value.chunk() {   // if it is a chunk
                if chunk.type == "goaltype" {  // and it is a goal
                    for (slot,val) in chunk.slotvals {
                        if slot != "isa" {
                            referenceList[slot] = val
                        }
                    }
                } else if let nestedGoal = chunk.slotvals["slot1"]?.chunk(), nestedGoal.type == "goaltype" {
                    for (slot, val) in chunk.slotvals {
                        if slot.hasPrefix("slot") && !slot.hasPrefix("slot1") && slot != "isa" {
                            if let slotValChunk = val.chunk(), let slotVal1 = slotValChunk.slotvals["slot1"], let slotVal2 = slotValChunk.slotvals["slot2"]  {
                                referenceList[slotVal1.description] = slotVal2
                            }
                        } else if !slot.hasPrefix("slot1") && slot != "isa" {
                            referenceList[slot] = val
                        }
                    }
                }
            }
        }
        var i = 1
        while let opSlotValue = opCopy.slotvals["slot\(i)"]  {
            if opSlotValue.description.hasPrefix("*") {
                var tempString = opSlotValue.description
                tempString.remove(at: tempString.startIndex)
                if let subst = referenceList[tempString] {
                    opCopy.setSlot("slot\(i)", value: subst)
                } else {
                    print("Cannot find \(opSlotValue.description)")
                    return nil
                }
            }
            i += 1
        }
/*                    var i = 1
                    while let opSlotValue = opCopy.slotvals["slot\(i)"]  {
                        if opSlotValue.chunk() != nil && opSlotValue.chunk()!.type == "reference" {
                            if let substitute = chunk.slotvals[opSlotValue.description] {
                                opCopy.setSlot("slot\(i)", value: substitute)
                            }
                        }
                        i += 1
                    }
                }
            }
        }
        // Check whether there are any references left
        // BUG: if we replace a reference by itself, it will be considered a mismatch here
        var i = 1
        while let opSlotValue = opCopy.slotvals["slot\(i)"] {
            if opSlotValue.chunk() != nil && opSlotValue.chunk()!.type == "reference" {
                return nil
            }
            i += 1
        }
 */
        return opCopy
    }
    
    /**
    This function collects all items that are currently in the context
 
    - returns: An array of (buffer name, slot name, value chunk) tuples
    */
    func allContextChunks() -> [(String, String, Chunk)] {
        var results: [(String, String, Chunk)] = []
        for (bufferName,bufferChunk) in model.buffers {
            for (slot,value) in bufferChunk.slotvals {
                if let chunk = value.chunk() {
                    results.append((bufferName, slot, chunk))
                }
            }
        }
        return results
    }
    
    /**
     This function finds an applicable operator and puts it in the operator buffer.
     
     - returns: Whether an operator was successfully found
     */
    func findOperator() -> Bool {
        let retrievalRQ = Chunk(s: "operator", m: model)
        retrievalRQ.setSlot("isa", value: "operator")
        var (latency,opRetrieved) = model.dm.retrieve(retrievalRQ)
        var cfs = model.dm.conflictSet.sorted(by: { (item1, item2) -> Bool in
            let (_,u1) = item1
            let (_,u2) = item2
            return u1 > u2
        })
        if !model.silent {
            model.addToTrace("Conflict Set", level: 5)
            for (chunk,activation) in cfs {
                let outputString = "  " + chunk.name + " A = " + String(format:"%.3f", activation) //+ "\(activation)"
                model.addToTrace(outputString, level: 5)
            }

        }
        var match = false
        var candidate: Chunk = Chunk(s: "empty", m: model)
        var candidateWithSubstitution: Chunk = Chunk(s: "empty", m: model)
        var activation: Double = 0.0
        var prim: Prim?
        if !cfs.isEmpty {
            repeat {
                (candidate, activation) = cfs.remove(at: 0)
                if let toBeCheckedOperator = checkOperatorGoalMatch(op: candidate) {
                    candidateWithSubstitution = toBeCheckedOperator.copyChunk()
                    model.buffers["operator"] = toBeCheckedOperator
                    let inst = model.procedural.findMatchingProduction()
                    (match, prim) = model.procedural.fireProduction(inst, compile: false)
                    model.buffers["imaginal"] = model.formerBuffers["imaginal"]
                    if let pr = prim {
                        if !match && !model.silent {
                            let s = "   Operator " + candidate.name + " does not match because of " + pr.name
                            model.addToTrace(s, level: 5)
                        }
                    }
                    // Temporary (?) commented out
                    //                    if match && candidate.spreadingActivation() <= 0.0 && model.buffers["operator"]?.slotValue("condition") != nil {
                    //                        match = false
                    //                        if !model.silent {
                    //                            let s = "   Rejected operator " + candidate.name + " because it has no associations and no production that tests all conditions"
                    //                            model.addToTrace(s, level: 2)
                    //                        }
                    //                        model.buffers["operator"] = nil
                    //                    }
                } else {
                    if !model.silent {
                        let s = "   Rejected operator " + candidate.name + " because its roles do not match any goal"
                        model.addToTrace(s, level: 3)
                    }
                }
            } while !match && !cfs.isEmpty && cfs[0].1 > model.dm.retrievalThreshold
        }
        if match {
            opRetrieved = candidate
            latency = model.dm.latency(activation)
        } else {
            opRetrieved = nil
            if !model.silent {
                model.addToTrace("   No matching operator found", level: 2)
            }
            latency = model.dm.latency(model.dm.retrievalThreshold)
        }
        model.time += latency
        if opRetrieved == nil { return false }
        if model.dm.goalOperatorLearning || model.dm.contextOperatorLearning {
            let item = (opRetrieved!, model.time - latency, model.dm.contextOperatorLearning ? allContextChunks() : [])
            previousOperators.append(item)
        }
        if !model.silent {
            if let opr = opRetrieved {
                model.addToTrace("*** Retrieved operator \(opr.name) with latency \(latency.string(fractionDigits: 3))", level: 1)
                //                print("*** Retrieved operator \(opr.name) with spread \(opr.spreadingActivation())")
            }
        }
        model.dm.addToFinsts(opRetrieved!)
        model.buffers["goal"]!.setSlot("last-operator", value: opRetrieved!)
        model.buffers["operator"] = candidateWithSubstitution
        model.formerBuffers["operator"] = candidateWithSubstitution.copyLiteral()
        
        return true
    }
    
    /**
        Remove the last operator record. To be called if an operator fails
    */
    func removeLastOperatorRecord() {
        if !previousOperators.isEmpty {
            _ = previousOperators.removeLast()
        }
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
                pname = String(pname.dropFirst())
            }
            if !model.silent {
                model.addToTrace("Firing \(pname)", level: 3)
            }
            model.firings += 1
            (match, _) = model.procedural.fireProduction(inst, compile: true)
            if first {
                model.time += model.procedural.productionActionLatency + model.imaginal.imaginalActionTime
                first = false
            } else {
                model.time += model.procedural.productionAndPrimLatency + model.imaginal.imaginalActionTime
            }
            model.imaginal.imaginalActionTime = 0.0
        }
        return match
    }
    
    
    
    /**
    Compile two operators into a single new operator that carries out all actions of the former operators
    while checking all conditions
     - parameter op1: The first to be compiled operator
     - parameter op2: The second to be compiled operator
     - returns: The compiled operator or nil if operators cannot be compiled
    */
    func compileOperators(op1: Chunk, op2: Chunk) -> Chunk! {
        // First, extract the conditions and actions, and separate them into their components
        let operator1 = Op(chunk: op1)
        var operator2 = Op(chunk: op2)
        // First, we need to check whether these operators can be compiled at all.
        // Two operators cannot fill the same slot (anywhere). Also check ">>" and "<<" in the actions (still need to check in conditions)
        // No compilation if second operator has a RT -> .. action
        // No compilation if first operator has an ->AC and second an V of any kind
        var hasV = false // to check for any V's in op2
        var hasAC = false // check for AC in op1
        for action1 in operator1.actions {
            if action1.rhsBuffer == "AC" { hasAC = true }
            for action2 in operator2.actions {
                if action1.op == ">>" || action1.op == "<<" || action2.op == ">>" || action2.op == "<<" { return nil }
                if action2.lhsBuffer == "RT" {
                    print("No compilation because action 2 has an RT action (i.e., a harvest from a retrieval result")
                    return nil }
                if action1.rhsBuffer == action2.rhsBuffer && action1.rhsSlot == action2.rhsSlot {
                    print("\(action1.rhsBuffer) \(action1.rhsSlot) appears in both actions, so no compilation")
                    return nil }
            }
        }
        // No compilation if any of the operators has either << or >> (need to figure out how to do that later)
        for condition in operator1.conditions {
            if condition.op == ">>" || condition.op == "<<" { return nil }
            if condition.lhsBuffer == "V" || condition.rhsBuffer == "V" { hasV = true }
        }
        for condition in operator2.conditions {
            if condition.op == ">>" || condition.op == "<<" { return nil }
            if condition.lhsBuffer == "V" || condition.rhsBuffer == "V" { hasV = true }
            if condition.lhsBuffer == "RT" && (condition.op != "<>" || condition.rhsBuffer != "") {
                print("No compilation because there is an RT in the conditions of the second operator")
                // But we allow checks for non-nil in the RT check
                return nil
            }
        }
        if hasV && hasAC { print("first operator has an AC while second operator has a V so no compilation")
            return nil }
        // That should cover all exclusions, now compile the operator
        var newOperator = Op(name:  operator1.name + "+" + operator2.name )
        // First we have to merge the constants
        newOperator.constants = operator1.constants // Start with the constants from operator1
        // Now add constants from operator2, unless the constant is already in the list
        for i in 0..<operator2.constants.count {
            let const = operator2.constants[i]
            var newIndex = -1
            if let j = operator1.constants.firstIndex(of: const) {
                newIndex = j + 1
            } else {
                newOperator.constants.append(const)
                newIndex = newOperator.constants.count
            }
            // Now replace all Ci's in operator2
            for j in 0..<operator2.conditions.count {
                if operator2.conditions[j].lhsBuffer == "C" && operator2.conditions[j].lhsSlot == i + 1 {
                    operator2.conditions[j].lhsSlot = newIndex
                }
                if operator2.conditions[j].rhsBuffer == "C" && operator2.conditions[j].rhsSlot == i + 1 {
                    operator2.conditions[j].rhsSlot = newIndex
                }
            }
            for j in 0..<operator2.actions.count {
                if operator2.actions[j].lhsBuffer == "C" && operator2.actions[j].lhsSlot == i + 1 {
                    operator2.actions[j].lhsSlot = newIndex
                }
            }
        }
        // Ok, now we have all the constants in the new operator, and all the references in operator2 index that list correctly
        // Now we assemble the conditions. Starting point are the conditions of operator1
        newOperator.conditions = operator1.conditions
        // Now look at each condition in operator2 and decide whether to add
        for condition in operator2.conditions {
            // First check whether either slot is modified by an operator1 action. If that is the case, we need to replace the reference in the new operator.
            var newCondition = condition
            if let i = operator1.actions.firstIndex(where: {(item) -> Bool in (item.rhsBuffer == condition.lhsBuffer) && (item.rhsSlot == condition.lhsSlot) }) {
//                print("Action matches condition in \(newOperator.name) condition lhs = \(newCondition.lhsBuffer) rhs = \(operator1.actions[i].lhsBuffer)")
                if (operator1.actions[i].lhsBuffer == "") { // We can't copy nil
                    return nil
                }
                newCondition.lhsBuffer = operator1.actions[i].lhsBuffer
                newCondition.lhsSlot = operator1.actions[i].lhsSlot
                }
            if let i = operator1.actions.firstIndex(where: {(item) -> Bool in (item.rhsBuffer == condition.rhsBuffer) && (item.rhsSlot == condition.rhsSlot) }) {
                newCondition.rhsBuffer = operator1.actions[i].lhsBuffer
                newCondition.rhsSlot = operator1.actions[i].lhsSlot
            }
//            print("New condition is \(newCondition)")
            if (newCondition.lhsBuffer != "" || newCondition.rhsBuffer != "") {
                newOperator.conditions.append(newCondition)
            }
        }
        /// This may not work if there are nil's involved, so fingers crossed.
        
        /// Now assemble the actions. Not so sure what can be pruned here so let's first try everything
        
        newOperator.actions = operator1.actions
        newOperator.actions.append(contentsOf: operator2.actions)
        
//        print("New operator")
//        print(newOperator)

        return newOperator.buildChunk(model: self.model)
    }
    
    
}
