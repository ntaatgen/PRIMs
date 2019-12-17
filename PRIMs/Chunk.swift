//
//  Chunk.swift
//  actr
//
//  Created by Niels Taatgen on 3/1/15.
//  Copyright (c) 2015 Niels Taatgen. All rights reserved.
//

import Foundation

class Chunk: NSObject, NSCoding {
    /// Name of the chunk
    let name: String
    /// Model in which the chunk is defined
    unowned let model: Model
    /// Time at which chunk entered DM. Nil if not a DM chunk (e.g., in a buffer)
    var creationTime: Double? = nil
    /// Number of references. Assume a single reference on creation
    var references: Int = 1
    /// Dictionary with slot-value pairs, initially empty
    var slotvals = [String:Value]()
    /// List of times at which chunks has been reinforced (assuming non-optimized learning)
    var referenceList = [Double]()
    /// How many other chunks does this chunk appear in?
    var fan: Int = 0
    /// What was the last noise value. Noise is only updated as time progresses
    var noiseValue: Double = 0
    /// At what time was noise last updated
    var noiseTime: Double = -1
    /// If base-level activation is fixed, this has a value
    var fixedActivation: Double? = nil
    /// Order in which the slots of the chunk are printed
    var printOrder: [String] = []
    /// Sji values
    var assocs: [String:(Double,Int)] = [:] // Sji table
    /// Task number that refers to the file that the chunk was defined in
    var definedIn: [Int] = []
    /// Is used to represent chunk trees in buffers: what is the parent Chunk?
    var parent: String? = nil
    /// The following instance variables are filled if the chunk is an operator
    /// An array of constants that are normally stored in slot1..n of the chunk
    var constants: [String] = []
    /// An array with the conditions. Each condition is a 5-tuple the 5 components of a PRIM
    var conditions: [(lhsBuffer: String, lhsSlot: Int, rhsBuffer: String, rhsSlot: Int, op: String)] = []
    /// An array with the actions. Each action is a 5-tuple with the 5 components of a PRIM
    var actions: [(lhsBuffer: String, lhsSlot: Int, rhsBuffer: String, rhsSlot: Int, op: String)] = []
    /**
    - returns: the type of the chunk, or empty string if there isn't one defined
    */
    var type: String {
        if let tp = slotvals["isa"] {
            return tp.description
        } else {
            return ""
        }
    }
    
    init (s: String, m: Model) {
        name = s
        model = m
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard let name = aDecoder.decodeObject(forKey: "name") as? String,
            let model = aDecoder.decodeObject(forKey: "model") as? Model,
            let slotvals = aDecoder.decodeObject(forKey: "slotvals") as? [String:String],
            let printOrder = aDecoder.decodeObject(forKey: "printorder") as? [String],
            let referenceList = aDecoder.decodeObject(forKey: "referencelist") as? [Double],
            let assoc1 = aDecoder.decodeObject(forKey: "assoc1") as? [String: Double],
            let assoc2 = aDecoder.decodeObject(forKey: "assoc2") as? [String: Int]
            else { return nil }
        self.init(s: name, m: model)
        for (slot,value) in slotvals {
            self.slotvals[slot] = Value.Text(value)
        }
        self.printOrder = printOrder
        self.fan = Int(aDecoder.decodeCInt(forKey: "fan"))
        self.references = Int(aDecoder.decodeCInt(forKey: "references"))
        let creationTime = aDecoder.decodeDouble(forKey: "creationtime")
        self.creationTime = creationTime == -1.0 ? nil : creationTime
        let fixedActivation = aDecoder.decodeDouble(forKey: "fixedactivation")
        self.fixedActivation = fixedActivation == -1000.0 ? nil : fixedActivation
        self.referenceList = referenceList
        for (chunk,value) in assoc1 {
            self.assocs[chunk] = (value, assoc2[chunk]!)
        }
    
    }

    func encode(with coder: NSCoder) {
        coder.encode(self.name, forKey: "name")
        coder.encode(self.model, forKey: "model")
        var slotvals: [String:String] = [:]
        for (slot,value) in self.slotvals {
            slotvals[slot] = value.description
        }
        coder.encode(slotvals, forKey: "slotvals")
        coder.encode(printOrder, forKey: "printorder")
        coder.encodeCInt(Int32(fan), forKey: "fan")
        coder.encodeCInt(Int32(references), forKey: "references")
        coder.encode(creationTime ?? -1.0, forKey: "creationtime")
        coder.encode(self.referenceList, forKey: "referencelist")
        coder.encode(fixedActivation ?? -1000.0, forKey: "fixedactivation")
        var assoc1: [String:Double] = [:]
        var assoc2: [String:Int] = [:]
        for (chunk, (s1, s2)) in assocs {
            assoc1[chunk] = s1
            assoc2[chunk] = s2
        }
        coder.encode(assoc1, forKey: "assoc1")
        coder.encode(assoc2, forKey: "assoc2")
    }
    
    /// A string with a printout of the Chunk
    override var description: String {
        get {
            var s = "\(name)\n"
            for slot in printOrder {
                if let val = slotvals[slot] {
                    s += "  \(slot)  \(val)\n"
                }
            }
            return s
        }
    }
    
    /**
    - returns: A copy of the chunk with a new name
    */
    func copyChunk() -> Chunk {
        let newChunk = model.generateNewChunk(self.name)
        newChunk.slotvals = self.slotvals
        newChunk.printOrder = self.printOrder
        newChunk.parent = self.parent
        return newChunk
    }
    
    /**
    - returns: A copy of the chunk with the same name
    */
    func copyLiteral() -> Chunk {
        let newChunk = Chunk(s: self.name, m: self.model)
        newChunk.slotvals = self.slotvals
        newChunk.printOrder = self.printOrder
        newChunk.parent = self.parent
        return newChunk
    }
    
    /**
    - parameter ch: A chunk

    - returns: Whether the chunk in the parameter is in one of the slots of the chunk
    */
    func inSlot(_ ch: Chunk) -> Bool {
        for (_,value) in ch.slotvals {
            if value.chunk() === self {
                return true
            }
        }
        return false
    }
    
    /**
    Set the creation time of the chunk to the current time
    */
    func startTime() {
        creationTime = model.time
        if !model.dm.optimizedLearning {
            referenceList.append(model.time)
        }
    }
    
    func setBaseLevel(_ timeDiff: Double, references: Int) {
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

    /**
    - returns: The current baselevel activation of the chunk
    */
    func baseLevelActivation () -> Double {
        if creationTime == nil { return 0 }
 
        let fixedComponent = fixedActivation == nil ? 0.0 : exp(fixedActivation!)
        if model.dm.optimizedLearning {
            let result = log(fixedComponent + (Double(references) * pow(model.time - creationTime! + 0.05, -model.dm.baseLevelDecay)) / (1 - model.dm.baseLevelDecay))
            if fixedActivation != nil && result < fixedActivation! {
                print("Detected under threshold chunk \(name) age \(model.time - creationTime!) references \(references)")
            }
            return result
        } else {
            return log(fixedComponent + self.referenceList.map{ pow((self.model.time - $0 + 0.05),(-self.model.dm.baseLevelDecay))}.reduce(0.0, + )) // Wew! almost lisp! This is the standard baselevel equation
        }
    }
    
    /**
    Add a reference to the chunk for the current model time
    */
    func addReference() {
        if creationTime == nil { return }
        if model.dm.optimizedLearning {
            references += 1
//            println("Added reference to \(self) references = \(references)")
        }
        else {
            referenceList.append(model.time)
        }
    }
    
    func setSlot(_ slot: String, value: Chunk) {
        if !printOrder.contains(slot) { printOrder.append(slot) }
        slotvals[slot] = Value.symbol(value)
    }
    
    @nonobjc
    func setSlot(_ slot: String, value: Double) {
        if !printOrder.contains(slot) { printOrder.append(slot) }
        slotvals[slot] = Value.Number(value)
    }
    
    @nonobjc
    func setSlot(_ slot: String, value: String) {
        if !printOrder.contains(slot) { printOrder.append(slot) }
        let possibleNumVal = string2Double(value) 
        if possibleNumVal != nil {
            slotvals[slot] = Value.Number(possibleNumVal!)
        } else if let chunk = model.dm.chunks[value] {
            setSlot(slot, value: chunk)
        } else {
            slotvals[slot] = Value.Text(value)
        }
    }
    
    @nonobjc
    func setSlot(_ slot: String, value: Value) {
        if !printOrder.contains(slot) { printOrder.append(slot) }
           slotvals[slot] = value
    }
    
    func slotValue(_ slot: String) -> Value? {
        if slot == "slot0" {
            return slotvals[slot] ?? .symbol(self)
        } else {
            return slotvals[slot]
        }
    }
    
//    double getSji (Chunk cj, Chunk ci)
//    {
//    if (cj.appearsInSlotsOf(ci)==0 && cj.name!=ci.name) return 0;
//    else return model.declarative.maximumAssociativeStrength - Math.log(cj.fan);
//    }
    
    func appearsInSlotOf(_ chunk: Chunk) -> Bool {
        for (_,value) in chunk.slotvals {
            switch value {
            case .symbol(let valChunk):
                if valChunk.name==self.name { return true }
            default: break
            }
        }
        return false
    }

    
    /**
    Add noise to an association value. This is currently only used for the Sji between goals and operators

    - returns: An Sji value with noise included
    */
    
    func calculateSji(_ sji: (Double,Int)) -> Double {
        let (base, references) = sji
        if references == 0 {
            return base
        } else {
            return base + model.dm.explorationExploitationFactor * actrNoise(model.dm.defaultOperatorAssoc) / sqrt(Double(references))
        }
    }
    
    /**
    Calculate the association between self and another chunk
    The chunk that receives the activation has the Sji in its list
    
    - parameter chunk: the chunk that the association is with
    
    - returns: the Sji value
    */
    func sji(_ chunk: Chunk, buffer: String? = nil, slot: String? = nil) -> Double {
        if model.dm.contextOperatorLearning && slot != nil {
            let value = chunk.assocs[buffer! + "%" + slot! + "%" + self.name]
            if value != nil {
                return calculateSji(value!)
            } else {
                return 0.0
            }
        }
        if let value = chunk.assocs[self.name] {
            return calculateSji(value)
        } else if self.appearsInSlotOf(chunk) {
            return max(0, model.dm.maximumAssociativeStrength - log(Double(max(1,self.fan))))
        }
        return 0.0
    }
    
    /**
    Calculate the spreading of activation from a certain buffer

    - parameter bufferName: The name of the buffer
    - parameter spreadingParameterValue: The amount of spreading from that particular buffer
    - returns: The amount of spreading activation from this buffer, and the number of slots involved in the spreading
    */
    func spreadingFromBuffer(_ bufferName: String, spreadingParameterValue: Double) -> (spreading: Double, slots: Int) {
        if spreadingParameterValue == 0 { return (spreading: 0, slots: 0) }
        var totalSji = 0.0
        var totalSlots: Int = 0
        if  let bufferChunk = model.buffers[bufferName] {
            for (slot,value) in bufferChunk.slotvals {
                switch value {
                case .symbol(let valchunk):
                    totalSji += valchunk.sji(self, buffer: bufferName, slot: slot)
//                    if valchunk.sji(self) != 0.0 {
//                        println("Buffer \(bufferName) slot \(value.description) to \(self.name) spreading \(valchunk.sji(self))")
//                    }
                    totalSlots += 1
                default:
                    break
                }
            }
            return (totalSlots==0 ? (spreading: 0, slots: 0) : (spreading: totalSji * (spreadingParameterValue / Double(totalSlots)), slots: totalSlots))

        }
        return (spreading: 0, slots: 0)
    }
    
    /**
    Calculate spreading activation for the chunk from the goal
    
    Can be calculated in two ways, either standard ACT-R's equation, or by making spreading dependent on the activation of the chunks in the goal slots
    
    - returns: The amount of spreading activation
    */
    func spreadingActivation() -> Double {
        if creationTime == nil {return 0}
        var totalSpreading: Double = 0
        var spreading = 0.0
        var totalSlots = 0
        if model.dm.goalSpreadingByActivation {
            if let goal=model.buffers["goal"] {
                for (_,value) in goal.slotvals {
                    switch value {
                    case .symbol(let valchunk):
                        totalSlots += 1
                        totalSpreading += valchunk.sji(self) * exp(valchunk.baseLevelActivation()) * model.dm.goalActivation
                    default:
                        break
                    }
                }
            }
        } else {
            (spreading, totalSlots) = spreadingFromBuffer("goal", spreadingParameterValue: model.dm.goalActivation)
            totalSpreading += spreading * Double(totalSlots)
        }
        /// The next piece of code calculated spreading for "constructed" goals
        if let goal=model.buffers["goal"] {
            for (_,value) in goal.slotvals {
                if value.chunk() != nil && value.chunk()!.type != "goaltype", let nestedGoal = value.chunk()?.slotvals["slot1"]?.chunk(), nestedGoal.type == "goaltype" {
                    if model.dm.goalSpreadingByActivation {
                        totalSpreading += nestedGoal.sji(self) * exp(value.chunk()!.baseLevelActivation()) * model.dm.goalActivation
                    } else {
                        totalSpreading += nestedGoal.sji(self) * model.dm.goalActivation
                    }
                }
            }
        }
        
        totalSpreading += spreadingFromBuffer("input", spreadingParameterValue: model.dm.inputActivation).spreading
        totalSpreading += spreadingFromBuffer("retrievalH", spreadingParameterValue: model.dm.retrievalActivation).spreading
        totalSpreading += spreadingFromBuffer("imaginal", spreadingParameterValue: model.dm.imaginalActivation).spreading
//        let val = spreadingFromBuffer("imaginal", spreadingParameterValue: model.dm.imaginalActivation)
//        print("Spreading from imaginal to \(self.name) is \(val) \(model.dm.imaginalActivation)")
        return totalSpreading
    }
    
    func calculateNoise() -> Double {
        if model.time != noiseTime {
            noiseValue = actrNoise(model.dm.activationNoise)
            noiseTime = model.time
        }
            return noiseValue
    }
    
    func activation() -> Double {
        if creationTime == nil {return 0}
        return  self.baseLevelActivation()
            + self.spreadingActivation() + calculateNoise()
    }
    
    func activationWithoutNoise() -> Double {
        if creationTime == nil {return 0}
        return  self.baseLevelActivation()
            + self.spreadingActivation()
    }

    
    func mergeAssocs(_ newchunk: Chunk) {
        for (name,value) in newchunk.assocs {
            if assocs[name] == nil {
                assocs[name] = value
            } else {
                assocs[name] = (max(assocs[name]!.0,value.0), assocs[name]!.1 + value.1)
            }
        }
    }
    
}

func == (left: Chunk, right: Chunk) -> Bool {
    // Are two chunks equal? They are if they have the same slots and values
    if left.slotvals.count != right.slotvals.count {   return false }
    for (slot1,value1) in left.slotvals {
        if let rightVal = right.slotvals[slot1] {
            if value1.description != rightVal.description {
                return false }
//            switch (rightVal,value1) {
//            case (.Number(let val1),.Number(let val2)): if val1 != val2 { return false }
//            case (.Text(let s1), .Text(let s2)): if s1 != s2 { return false }
//            case (.Symbol(let c1), .Symbol(let c2)): if c1 !== c2 { return false }
//            default: return false
//            }
        } else {
            return false }
    }
    return true
}

func != (left: Chunk, right: Chunk) -> Bool {
    return !(left == right)
}

