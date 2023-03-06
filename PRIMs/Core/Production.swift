//
//  Production.swift
//  act-r
//
//  Created by Niels Taatgen on 3/29/15.
//  Copyright (c) 2015 Niels Taatgen. All rights reserved.
//

import Foundation

class Production: NSObject, NSCoding {
    let name: String
    var fullName: String!
    unowned let model: Model
//    weak var model: Model!
    let condition: String?
    let action: String?
    var newCondition: String?
    var newAction: String?
    var conditions: [Prim] = []
    var actions: [Prim] = []
    var u: Double
    var goalChecks: [Chunk] = []
    let parent1: Production?
    let parent2: Production?
    let taskID: Int
    override var description: String {
        get {
            var s = "(p \(name)\n"
            let empty = "empty"
            s += "   Transforms condition \(condition ?? empty) into \(newCondition ?? empty)\n"
            s += "   Transforms action \(action ?? empty) into \(newAction ?? empty)\n"

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
    
    
    init(name: String, model: Model, condition: String?, action: String?, parent1: Production?, parent2: Production?, taskID: Int, u: Double) {
        self.name = name
        self.model = model
        self.condition = condition
        self.action = action
        self.newCondition = condition
        self.newAction = action
        self.u = u
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
 
    required convenience init?(coder aDecoder: NSCoder) {
        guard let model = aDecoder.decodeObject(forKey: "model") as? Model,
            let name = aDecoder.decodeObject(forKey: "name") as? String,
        let condition = aDecoder.decodeObject(forKey: "condition") as? String?,
        let action = aDecoder.decodeObject(forKey: "action") as? String?,
        let parent1 = aDecoder.decodeObject(forKey: "parent1") as? Production?,
        let parent2 = aDecoder.decodeObject(forKey: "parent2") as? Production?,
        let fullName = aDecoder.decodeObject(forKey: "fullname") as? String?,
        let newCondition = aDecoder.decodeObject(forKey: "newcondition") as? String?,
        let newAction = aDecoder.decodeObject(forKey: "newaction") as? String?,
        let goalChecks = aDecoder.decodeObject(forKey: "goalchecks") as? [Chunk],
        let conditions = aDecoder.decodeObject(forKey: "conditions") as? [Prim],
        let actions = aDecoder.decodeObject(forKey: "actions") as? [Prim]
            else { return nil }
        self.init(name: name, model: model, condition: condition, action: action, parent1: parent1, parent2: parent2, taskID: -3, u: aDecoder.decodeDouble(forKey: "utility"))
        self.fullName = fullName
        self.newCondition = newCondition
        self.newAction = newAction
        self.goalChecks = goalChecks
        self.conditions = conditions
        self.actions = actions
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(self.model, forKey: "model")
        coder.encode(self.name, forKey: "name")
        coder.encode(self.condition ?? "nil", forKey: "condition")
        coder.encode(self.action ?? "nil", forKey: "action")
        coder.encode(self.parent1, forKey: "parent1")
        coder.encode(self.parent2, forKey: "parent2")
        coder.encodeCInt(Int32(self.taskID), forKey: "taskID")
        coder.encode(self.u, forKey: "utility")
        coder.encode(self.fullName, forKey: "fullname")
        coder.encode(self.newCondition, forKey: "newcondition")
        coder.encode(self.newAction, forKey: "newaction")
        coder.encode(self.goalChecks, forKey: "goalchecks")
        coder.encode(self.conditions, forKey: "conditions")
        coder.encode(self.actions, forKey: "actions")
    }
    func setFullName() {
        fullName = name + "|" + newCondition! + ";" + newAction!
    }
    
    func addCondition(_ cd: Prim) {
        conditions.append(cd)
        let (_,new) = chopPrims(condition!, n: conditions.count)
        newCondition = new == "" ? nil : new
    }
    
    func addAction(_ ac: Prim) {
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
        }
//        else if op != nil {
//            for chunk in goalChecks {
//                if !chunk.inSlot(model.buffers["goal"]!) {
////                    println("Chunk \(chunk) is not in goal")
//                    return nil
//                }
//            }
//            model.buffers["operator"] = op!.copyChunk()
//            for cd in conditions {
//                if !cd.fire(condition: true) {
//                    model.buffers["operator"] = nil
//
//                    return nil }
//            }
//            model.buffers["operator"] = nil
//            let utility = u + actrNoise(model.procedural.utilityNoise)
//            let inst = Instantiation(prod: self, time: model.time, u: utility)
//            return inst
//        }
        return nil        
    }
    
    func testFire() -> (Bool, Prim?, Double) {

        for bc in conditions {
            if !bc.fire(condition: true).match { // println("\(bc) does not match")
                return (false, bc, 0) } // one of the conditions does not match
        }
//        for ac in actions {
//            if !ac.testFire() {
//                return (false, ac)
//            }
//        }
        if newCondition != nil {
            model.buffers["operator"]!.setSlot("condition", value: newCondition!)
        } else {
            model.buffers["operator"]!.slotvals["condition"] = nil
        }

        return (true, nil, 0)
    }
    
    /**
    Function that executes all the production's actions
    
    - returns:  Whether execution was successful
    */
    func fire() -> (Bool, Prim?, Double) {
        var latency = 0.0
        for bc in conditions {
            if !bc.fire(condition: true).match { // println("\(bc) does not match")
                return (false, bc, 0.0) } // one of the conditions does not match
        }
        for ac in actions {
            let acFire = ac.fire(condition: false)
            if !acFire.match { // println("\(ac) does not execute")
                return (false, ac, 0.0) } // an action cannot be executed because its lhs is nil
            latency += acFire.latency
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
        return (true, nil, latency)
    }
    
}
