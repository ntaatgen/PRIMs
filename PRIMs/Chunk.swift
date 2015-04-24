//
//  Chunk.swift
//  actr
//
//  Created by Niels Taatgen on 3/1/15.
//  Copyright (c) 2015 Niels Taatgen. All rights reserved.
//

import Foundation

class Chunk: Printable {

    let name: String
    let model: Model
    var creationTime: Double? = nil
    var references: Int = 1 // Number of references. Assume a single reference on creation
    var slotvals = [String:Value]() // Dictionary with slot-value pairs, initially empty
    var referenceList = [Double]()
    var fan: Int = 0 // in how many other chunks does dit chunk appear?
    var noiseValue: Double = 0 // What was the last noise value
    var noiseTime: Double = -1 // When was noise last calculated?
    var fixedActivation: Double? = nil // Sometimes we want to fix baselevelactivation
    var isRequest: Bool = false
    var printOrder: [String] = [] // Order in which slots have to be printed
    var assocs: [String:Double] = [:] // Sji table
    init (s: String, m: Model) {
        name = s
        model = m
    }
    
    var description: String {
        get {
//            let actv = self.activation()
            var s = "\(name)\n"
            for slot in printOrder {
                if let val = slotvals[slot] {
                    s += "  \(slot)  \(val)\n"
                }
            }
//            for (slot,val) in slotvals {
//                s += "  \(slot)  \(val)\n"
//            }
//            if creationTime != nil {
//                s += "Fan = \(fan)  Activation = \(actv)"
//            }
            return s
        }
    }
    
    func copy() -> Chunk {
        let newChunk = model.generateNewChunk(s1: self.name)
        newChunk.slotvals = self.slotvals
        return newChunk
    }
    
    func inSlot(ch: Chunk) -> Bool {
        for (_,value) in ch.slotvals {
            if value.chunk() === self {
                return true
            }
        }
        return false
    }
    
    func startTime() {
        creationTime = model.time
        if !model.dm.optimizedLearning {
            referenceList.append(model.time)
        }
    }
    
    func setBaseLevel(timeDiff: Double, references: Int) {
        creationTime = model.time + timeDiff
        if model.dm.optimizedLearning {
            self.references = references
        } else {
            let increment = -timeDiff / Double(references)
            for i in 0..<references {
                let referenceTime = creationTime! + Double(i) * increment
              referenceList.append(referenceTime)
            }
        }
    }
//    
//    baseLevel = Math.log(useCount/(1-model.declarative.baseLevelDecayRate))
//    - model.declarative.baseLevelDecayRate*Math.log(time-creationTime);

    
    func baseLevelActivation () -> Double {
        if creationTime == nil { return 0 }
        if fixedActivation != nil {
            return fixedActivation!
        } else if model.dm.optimizedLearning {
            let x: Double = log((Double(references)/(1 - model.dm.baseLevelDecay)))
            let y = model.dm.baseLevelDecay + log(model.time - creationTime!)
            return x - y
        } else {
            return log(reduce(map(self.referenceList){ pow((self.model.time - $0),(-self.model.dm.baseLevelDecay))}, 0.0, + )) // Wew! almost lisp! This is the standard baselevel equation
        }
    }
    
    func addReference() {
        if creationTime == nil { return }
        if model.dm.optimizedLearning {
            references += 1
            println("Added reference to \(self) references = \(references)")
        }
        else {
            referenceList.append(model.time)
        }
    }
    
    func setSlot(slot: String, value: Chunk) {
        if slotvals[slot] == nil { printOrder.append(slot) }
        slotvals[slot] = Value.Symbol(value)
    }
    
    func setSlot(slot: String, value: Double) {
        if slotvals[slot] == nil { printOrder.append(slot) }
        slotvals[slot] = Value.Number(value)
    }

    func setSlot(slot: String, value: String) {
        if slotvals[slot] == nil { printOrder.append(slot) }
        let possibleNumVal = NSNumberFormatter().numberFromString(value)?.doubleValue
        if possibleNumVal != nil {
            slotvals[slot] = Value.Number(possibleNumVal!)
        }
        if let chunk = model.dm.chunks[value] {
            slotvals[slot] = Value.Symbol(chunk)
        } else {
            slotvals[slot] = Value.Text(value)
        }
    }
    
    func setSlot(slot: String, value: Value) {
        if slotvals[slot] == nil { printOrder.append(slot) }
           slotvals[slot] = value
    }
    
    func slotValue(slot: String) -> Value? {
        return slotvals[slot]
    }
    
//    double getSji (Chunk cj, Chunk ci)
//    {
//    if (cj.appearsInSlotsOf(ci)==0 && cj.name!=ci.name) return 0;
//    else return model.declarative.maximumAssociativeStrength - Math.log(cj.fan);
//    }
    
    func appearsInSlotOf(chunk: Chunk) -> Bool {
        for (_,value) in chunk.slotvals {
            switch value {
            case .Symbol(let valChunk):
                if valChunk.name==self.name { return true }
            default: break
            }
        }
        return false
    }

    
    func sji(chunk: Chunk) -> Double {
        if let value = chunk.assocs[self.name] {
            return value
        } else if self.appearsInSlotOf(chunk) {
            return model.dm.maximumAssociativeStrength - log(Double(self.fan))
        }
        return 0.0
    }
    
    func spreadingActivation() -> Double {
        if creationTime == nil {return 0}
        if let goal=model.buffers["goal"] {
            var totalSlots: Int = 0
            var totalSji: Double = 0
            for (_,value) in goal.slotvals {
                switch value {
                case .Symbol(let valchunk):
                    totalSji += valchunk.sji(self)
                    totalSlots++
                default:
                    break
                }
            }
            return (totalSlots==0 ? 0 : totalSji * (model.dm.goalActivation / Double(totalSlots)))
            
        }
        return 0
    }
    
    func calculateNoise() -> Double {
        if model.time != noiseTime {
            noiseValue = (model.dm.activationNoise == nil ? 0.0 : actrNoise(model.dm.activationNoise!))
            noiseTime = model.time
        }
            return noiseValue
    }
    
    func activation() -> Double {
        if creationTime == nil {return 0}
//        if self.slotvals["isa"]!.description == "operator" {
//            println("Spreading activation of \(self.name) is \(self.spreadingActivation())")
//        }
        return  self.baseLevelActivation()
            + self.spreadingActivation() + calculateNoise()
    }
    
}

func == (left: Chunk, right: Chunk) -> Bool {
    // Are two chunks equal? They are if they have the same slots and values
    if left.slotvals.count != right.slotvals.count { return false }
    for (slot1,value1) in left.slotvals {
        if let rightVal = right.slotvals[slot1] {
            switch (rightVal,value1) {
            case (.Number(let val1),.Number(let val2)): if val1 != val2 { return false }
            case (.Text(let s1), .Text(let s2)): if s1 != s2 { return false }
            case (.Symbol(let c1), .Symbol(let c2)): if c1 !== c2 { return false }
            default: return false
            }
        } else { return false }
    }
    return true
}