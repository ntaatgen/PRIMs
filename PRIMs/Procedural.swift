//
//  Procedural.swift
//  act-r
//
//  Created by Niels Taatgen on 3/29/15.
//  Copyright (c) 2015 Niels Taatgen. All rights reserved.
//

import Foundation

class Procedural: NSObject, NSCoding {
    static let utilityNoiseDefault = 0.05
    var utilityNoise = utilityNoiseDefault
    static let defaultUdefault = 0.0
    var defaultU = defaultUdefault
    static let primUDefault = 2.0
    var primU = primUDefault
    static let utilityRetrieveOperatorDefault = 2.0
    var utilityRetrieveOperator = utilityRetrieveOperatorDefault
    static let alphaDefault = 0.1
    var alpha = alphaDefault
    static let productionActionLatencyDefault = 0.05
    var productionActionLatency = productionActionLatencyDefault
    static let productionAndPrimLatencyDefault = 0.3
    var productionAndPrimLatency = productionAndPrimLatencyDefault
    static let proceduralRewardDefault = 4.0
    var proceduralReward = proceduralRewardDefault
    var productions: [String:Production] = [:]
    unowned let model: Model
    var productionsForReward: [Instantiation] = []
    var lastProduction: Production? = nil
    var lastOperator: Chunk? = nil
    var retrieveOperatorsConditional = true // if true, operator retrieval is controlled by productions that check the match
    
    init(model: Model) {
        self.model = model
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard let model = aDecoder.decodeObject(forKey: "model") as? Model,
            let productions = aDecoder.decodeObject(forKey: "productions") as? [String:Production]
            else { return nil }
        self.init(model: model)
        self.productions = productions
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(self.model, forKey: "model")
        coder.encode(self.productions, forKey: "productions")
    }
    
    func setParametersToDefault() {
        utilityNoise = Procedural.utilityNoiseDefault
        defaultU = Procedural.defaultUdefault
        primU = Procedural.primUDefault
        utilityRetrieveOperator = Procedural.utilityRetrieveOperatorDefault
        alpha = Procedural.alphaDefault
        productionActionLatency = Procedural.productionActionLatencyDefault
        productionAndPrimLatency = Procedural.productionAndPrimLatencyDefault
        proceduralReward = Procedural.proceduralRewardDefault
    }
    
    func reset() {
        lastProduction = nil
        clearRewardTrace()
    }
    
    func addProduction(_ p: Production) {
        productions[p.name] = p
    }
    

    
    /**
    Clear the list of productions that fired since the last reward
    */
    func clearRewardTrace() {
        productionsForReward = []
    }
    
    /**
    Add an instantiation to the reward list
    */
    func addToRewardTrace(_ i: Instantiation) {
        productionsForReward.append(i)
    }
    
    /**
    Issue a reward to all the productions that fired since the last reward, then clear the list
    */
    func issueReward(_ reward: Double) {
        for inst in productionsForReward {
            let payoff = reward   - (model.time - inst.time) 
            inst.p.u = inst.p.u + alpha * (payoff - inst.p.u)
        }
        clearRewardTrace()
    }
    
    func fireProduction(_ inst: Instantiation, compile: Bool) -> (Bool, Prim?) {

        if compile {
            if !inst.p.name.hasPrefix("t") {
                addToRewardTrace(inst)
            }
            if lastProduction != nil {
                compileProductions(lastProduction!, inst2: inst)
            }
            lastProduction = inst.p
            return inst.p.fire()
        } else {
            return inst.p.testFire()
        }
    }
    
    /**
    Return the production with the highest utility, or a production with just one PRIM if no production
    is above threshold
    */
    func findMatchingProduction() -> Instantiation {
        let condition = model.buffers["operator"]?.slotvals["condition"]
        let action = model.buffers["operator"]?.slotvals["action"]
        var best: Instantiation? = nil
        for (_,p) in productions {
            if let ins = p.instantiate() {
                if best == nil || best!.u < ins.u {
                    best = ins
                }
            }
            
        }
        if best == nil || best!.u < primU {
            if condition != nil {
                let (primName,_) = chopPrims(condition!.description, n: 1)
                let p = Production(name: "t" + primName, model: model, condition: condition!.description, action: action==nil ? nil : action!.description, op: nil, parent1: nil, parent2: nil, taskID: 0, u: primU)
                let prim = Prim(name: primName, model: model)
                p.addCondition(prim)
                return Instantiation(prod: p, time: model.time, u: primU)
            } else {
                let (primName,_) = chopPrims(action!.description, n: 1)
                let p = Production(name: "t" + primName, model: model, condition: nil, action: action!.description, op: nil, parent1: nil, parent2: nil, taskID: 0, u: primU)
                let prim = Prim(name: primName, model: model)
                p.addAction(prim)
                return Instantiation(prod: p, time: model.time, u: primU)
            }
        } else {
            return best!
        }
    }
    
    func findOperatorProduction() -> Instantiation? {
        var best: Instantiation? = nil
        var ins: Instantiation?
        for (_,p) in productions {
            if p.op != nil {
                ins = p.instantiate()
                if ins != nil {

                    
                    if best == nil || best!.u < ins!.u {
                        best = ins!
                    }
                }
            }
        }
        if best == nil || best!.u < utilityRetrieveOperator {
            return nil
        } else {
            return best!
        }
    }
    
    
    func compileProductions(_ p1: Production, inst2: Instantiation) {
        let p2 = inst2.p
        let nameP1 = p1.name.hasPrefix("t") ? p1.name.substring(from: p1.name.characters.index(p1.name.startIndex, offsetBy: 1)) : p1.name
        let nameP2 = p2.name.hasPrefix("t") ? p2.name.substring(from: p2.name.characters.index(p2.name.startIndex, offsetBy: 1)) : p2.name
        let newName = nameP1 + ";" + nameP2
        var newFullName = newName
        if p2.newCondition != nil {
            newFullName = newFullName + "|" + p2.newCondition!
        }
        if p2.newAction != nil {
            newFullName = newFullName + "|" + p2.newAction!
            
        }
        if let existingP = productions[newFullName] {
            existingP.u += alpha * (p1.u - existingP.u)
            if !model.silent {
                let s = "Reinforcing " + existingP.name + " new u = " + String(format:"%.3f", existingP.u)
                model.addToTrace(s, level: 4)
            }
            
        } else {
            let newP = Production(name: newName, model: model, condition: p1.condition, action: p1.action, op: p1.op, parent1: p1, parent2: p2, taskID: model.currentTaskIndex!, u: defaultU)
            newP.conditions = p1.conditions + p2.conditions
            newP.actions = p1.actions + p2.actions
            newP.newCondition = p2.newCondition
            newP.newAction = p2.newAction
            newP.goalChecks = p1.goalChecks
            newP.fullName = newFullName
            productions[newP.fullName] = newP
            
            if !model.silent {
                model.addToTrace("Compiling \(newP.name)", level: 4)
            }
            
        }
        
    }
    
    /// Need to either fix this or delete it
//    func compileProductions(op: Chunk, inst2: Instantiation) {
//        let p2 = inst2.p
//        let nameP2 = p2.name.hasPrefix("t") ? p2.name.substringFromIndex(advance(p2.name.startIndex,1)) : p2.name
//        let newName = op.name + ";" + nameP2
//        if p2.newCondition != nil || p2.op != nil { return } // production has to clear the conditions, and we do not compile over 2 operators (yet)
//        if let existingP = productions[newName] {
//            existingP.u += alpha * (utilityRetrieveOperator - existingP.u)
//            model.addToTrace("Reinforcing \(existingP.name) new u = \(existingP.u)")
//        } else {
//            let newP = Production(name: newName, model: model, condition: nil, action: nil, op: op, parent1: p2, parent2: nil, taskID: model.currentTaskIndex!)
//            newP.conditions = p2.conditions
//            newP.actions = p2.actions
//            newP.newCondition = nil
//            newP.newAction = p2.newAction
//            for (assoc,_) in op.assocs {
//                newP.goalChecks.append(model.dm.chunks[assoc]!)
//            }
//            productions[newP.name] = newP
//            model.addToTrace("Compiling \(newP)")
//        }
//    }
    
}
