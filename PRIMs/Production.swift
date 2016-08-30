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
    override var description: String {
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
    
    
    init(name: String, model: Model, condition: String?, action: String?, op: Chunk?, parent1: Production?, parent2: Production?, taskID: Int, u: Double) {
        self.name = name
        self.model = model
        self.condition = condition
        self.action = action
        self.newCondition = condition
        self.newAction = action
        self.op = op
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
        guard let model = aDecoder.decodeObjectForKey("model") as? Model,
            let name = aDecoder.decodeObjectForKey("name") as? String,
        let condition = aDecoder.decodeObjectForKey("condition") as? String?,
        let action = aDecoder.decodeObjectForKey("action") as? String?,
        let op = aDecoder.decodeObjectForKey("op") as? Chunk?,
        let parent1 = aDecoder.decodeObjectForKey("parent1") as? Production?,
        let parent2 = aDecoder.decodeObjectForKey("parent2") as? Production?,
        let fullName = aDecoder.decodeObjectForKey("fullname") as? String?,
        let newCondition = aDecoder.decodeObjectForKey("newcondition") as? String?,
        let newAction = aDecoder.decodeObjectForKey("newaction") as? String?,
        let goalChecks = aDecoder.decodeObjectForKey("goalchecks") as? [Chunk],
        let conditions = aDecoder.decodeObjectForKey("conditions") as? [Prim],
        let actions = aDecoder.decodeObjectForKey("actions") as? [Prim]
            else { return nil }
        self.init(name: name, model: model, condition: condition, action: action, op: op, parent1: parent1, parent2: parent2, taskID: -3, u: aDecoder.decodeDoubleForKey("utility"))
        self.fullName = fullName
        self.newCondition = newCondition
        self.newAction = newAction
        self.goalChecks = goalChecks
        self.conditions = conditions
        self.actions = actions
    }
    
    func encodeWithCoder(coder: NSCoder) {
        coder.encodeObject(self.model, forKey: "model")
        coder.encodeObject(self.name, forKey: "name")
        coder.encodeObject(self.condition ?? "nil", forKey: "condition")
        coder.encodeObject(self.action ?? "nil", forKey: "action")
        coder.encodeObject(self.op, forKey: "op")
        coder.encodeObject(self.parent1, forKey: "parent1")
        coder.encodeObject(self.parent2, forKey: "parent2")
        coder.encodeInt(Int32(self.taskID), forKey: "taskID")
        coder.encodeDouble(self.u, forKey: "utility")
        coder.encodeObject(self.fullName, forKey: "fullname")
        coder.encodeObject(self.newCondition, forKey: "newcondition")
        coder.encodeObject(self.newAction, forKey: "newaction")
        coder.encodeObject(self.goalChecks, forKey: "goalchecks")
        coder.encodeObject(self.conditions, forKey: "conditions")
        coder.encodeObject(self.actions, forKey: "actions")
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
    
    func testFire() -> (Bool, Prim?) {
        if op != nil {
            model.buffers["operator"] = op!.copy()
        }
        for bc in conditions {
            if !bc.fire() { // println("\(bc) does not match")
                return (false, bc) } // one of the conditions does not match
        }
        for ac in actions {
            if !ac.testFire() {
                return (false, ac)
            }
        }
        if newCondition != nil {
            model.buffers["operator"]!.setSlot("condition", value: newCondition!)
        } else {
            model.buffers["operator"]!.slotvals["condition"] = nil
        }

        return (true, nil)
    }
    
    /**
    Function that executes all the production's actions
    
    - returns:  Whether execution was successful
    */
    func fire() -> (Bool, Prim?) {
//        if op != nil {
//            model.buffers["operator"] = op!.copy()
//        }
        for bc in conditions {
            if !bc.fire() { // println("\(bc) does not match")
                return (false, bc) } // one of the conditions does not match
        }
        for ac in actions {
            if !ac.fire() { // println("\(ac) does not execute")
                return (false, ac) } // an action cannot be executed because its lhs is nil
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
        return (true, nil)
    }
    
}