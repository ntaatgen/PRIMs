//
//  Production.swift
//  act-r
//
//  Created by Niels Taatgen on 3/29/15.
//  Copyright (c) 2015 Niels Taatgen. All rights reserved.
//

import Foundation

class Production: CustomStringConvertible {
    let name: String
    var fullName: String!
    weak var model: Model!
    let condition: String?
    let action: String?
    let op: Chunk?
    var newCondition: String?
    var newAction: String?
    var conditions: [Prim] = []
    var actions: [Prim] = []
    var u: Double
    var goalChecks: [Chunk] = []
    let parent1: Production?
    let parent2: Production?
    let taskID: Int
    var description: String {
        get {
            var s = "(p \(name)\n"
            s += "   Transforms condition \(condition) into \(newCondition)\n"
            s += "   Transforms action \(action) into \(newAction)\n"
            if op != nil {
                s += "   Includes operator \(op!.name)\n"
            }
            for gc in goalChecks {
                s += "   Checks for \(gc.name) in the goal\n"
            }
            for cd in conditions {
                s += "   " + cd.description + "\n"
            }
            s += "==>\n"
            for ac in actions {
                s += "   " + ac.description + "\n"
            }
            return s + ")\n" + "Utility = \(u)\n"
            
        }
    }
    
    
    init(name: String, model: Model, condition: String?, action: String?, op: Chunk?, parent1: Production?, parent2: Production?, taskID: Int) {
        self.name = name
        self.model = model
        self.condition = condition
        self.action = action
        self.newCondition = condition
        self.newAction = action
        self.op = op
        self.u = model.procedural.defaultU
        if parent1 == nil || parent1!.name.hasPrefix("t") {
            self.parent1 = nil
        } else {
            self.parent1 = parent1!
        }
        if parent2 == nil || parent2!.name.hasPrefix("t") {
            self.parent2 = nil
        } else {
            self.parent2 = parent2
        }
        self.taskID = taskID
    }
    
    func setFullName() {
        fullName = name + "|" + newCondition! + ";" + newAction!
    }
    
    func addCondition(cd: Prim) {
        conditions.append(cd)
        let (_,new) = chopPrims(condition!, n: conditions.count)
        newCondition = new == "" ? nil : new
    }
    
    func addAction(ac: Prim) {
        actions.append(ac)
        let (_,new) = chopPrims(action!, n: actions.count)
        newAction = new == "" ? nil : new
    }
    
    /**
    This function checks whether a production can fire, which is the case if it matches both the
    condition and action in the operator buffer
    
    - returns: If the production can be instantiated with the current buffers, otherwise nil
    */
    func instantiate() -> Instantiation? {

        if let opBuffer = model.buffers["operator"] {
            if condition == opBuffer.slotvals["condition"]?.text() && action == opBuffer.slotvals["action"]?.text() {
                let utility = u + actrNoise(model.procedural.utilityNoise)
                let inst = Instantiation(prod: self, time: model.time, u: utility)
                        return inst
            }
        } else if op != nil {
            for chunk in goalChecks {
                if !chunk.inSlot(model.buffers["goal"]!) {
//                    println("Chunk \(chunk) is not in goal")
                    return nil
                }
            }
            model.buffers["operator"] = op!.copy()
            for cd in conditions {
                if !cd.fire() {
                    model.buffers["operator"] = nil

                    return nil }
            }
            model.buffers["operator"] = nil
            let utility = u + actrNoise(model.procedural.utilityNoise)
            let inst = Instantiation(prod: self, time: model.time, u: utility)
            return inst
        }
        return nil        
    }
    
    func testFire() -> Bool {
        if op != nil {
            model.buffers["operator"] = op!.copy()
        }
        for bc in conditions {
            if !bc.fire() { // println("\(bc) does not match")
                return false } // one of the conditions does not match
        }
        for ac in actions {
            if !ac.testFire() {
                return false
            }
        }
        if newCondition != nil {
            model.buffers["operator"]!.setSlot("condition", value: newCondition!)
        } else {
            model.buffers["operator"]!.slotvals["condition"] = nil
        }

        return true
    }
    
    /**
    Function that executes all the production's actions
    
    - returns:  Whether execution was successful
    */
    func fire() -> Bool {
//        if op != nil {
//            model.buffers["operator"] = op!.copy()
//        }
        for bc in conditions {
            if !bc.fire() { // println("\(bc) does not match")
                return false } // one of the conditions does not match
        }
        for ac in actions {
            if !ac.fire() { // println("\(ac) does not execute")
                return false } // an action cannot be executed because its lhs is nil
        }
        if newCondition != nil {
            model.buffers["operator"]!.setSlot("condition", value: newCondition!)
        } else {
            model.buffers["operator"]!.slotvals["condition"] = nil
        }
        if newAction != nil {
            model.buffers["operator"]!.setSlot("action", value: newAction!)
        } else {
            model.buffers["operator"]!.slotvals["action"] = nil
        }
        return true
    }
    
}