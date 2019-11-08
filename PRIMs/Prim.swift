//
//  Prim.swift
//  
//
//  Created by Niels Taatgen on 4/17/15.
//
//

import Foundation
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


/// Buffer mappings for buffers that can be used as source (in condition or lhs of action)
let bufferMappingC = ["V":"input","WM":"imaginal","G":"goal","C":"operator","AC":"action","RT":"retrievalH","GC":"constants","T":"temporal"]
/// Buffer mappings for buffer that are used in the rhs of an action
let bufferMappingA = ["V":"input","WM":"imaginal","G":"goal","C":"operator","AC":"action","RT":"retrievalR","GC":"constants","T":"temporal"]
/// Buffer mappings for push and pop
let bufferMappingPP = ["V":"input", "WM":"imaginal","G":"goal","RT":"retrievalH"]
/// Buffer Order determines which buffer is preferred on the left side of a PRIM (lower is left)
let bufferOrder = ["input":1,"goal":2,"imaginal":3,"retrievalH":4,"constants":5,"operator":6,"temporal":7]


// New PRIMs to implement
// >>bufferslot
// buffer<<
// something->G
// nil->G

// Attempt for a new parseName function using regular expressions instead of the current horror :)

/** 
This function takes a string that represents a PRIM, and translates it into its components

- returns: is a six-tuple with left-buffer-name left-buffer-slot, operator, right-buffer-name, right-buffer-slot, PRIM with reversed lhs and rhs if necessary
*/
func parseName(_ name: String) -> (String?,String?,String,String?,String?,String?) {
    var components: [String] = []
    var component = ""
    var prevComponentCat: Int? = nil
    for ch in name {
        var componentCat: Int
        switch ch {
        case "A"..."Z", "a"..."z", "*":  componentCat = 1
        case "0"..."9":  componentCat = 2
        case "<",">","=","-":  componentCat = 3
        default:  componentCat = -1
        }
        if prevComponentCat == nil {
            prevComponentCat = componentCat
        }
        if prevComponentCat! == componentCat {
            component += String(ch)
        } else {
            components.append(component)
            component = String(ch)
        }
        prevComponentCat = componentCat
    }
    components.append(component)
    // First handle the new special cases
    if components.count > 0 && components[0] == ">>" {
        if components.count == 3 {
            return (nil, nil, components[0], bufferMappingPP[components[1]], "slot" + components[2], nil)  /// Need to check this!
        } else {
            return ("", "", "", nil, nil, nil)
        }
    }
    if components.count > 1 && components[1] == "<<" {
        if components.count == 2 {
            return(bufferMappingPP[components[0]], nil, components[1], nil, nil, nil)
        } else {
            return ("", "", "", nil, nil, nil)
        }
    }
    
    let compareError = components.count < 4
    let parseError = compareError || (components[0] != "nil" && components[3] != "nil" && (components.count == 4 || bufferMappingC[components[3]] == "nil"))
    if  parseError || components[0] == "nil" && components[1] != "->" {
        return ("","","",nil,nil,nil)
    } else if components[0] == "nil" {
        let rightBuffer = bufferMappingA[components[2]]
        if rightBuffer == nil { return ("","","",nil,nil,nil) }
        return (nil,nil,"->",rightBuffer!,"slot" + components[3],nil)
    } else if components[3] == "nil" {
        let leftBuffer = bufferMappingC[components[0]]
        if leftBuffer == nil { return ("","","",nil,nil,nil) }
        return (leftBuffer!,"slot" + components[1],components[2],nil,nil,nil)
    } else {
        var rightBuffer = (components[2] == "->") ? bufferMappingA[components[3]] : bufferMappingC[components[3]]
        var leftBuffer = bufferMappingC[components[0]]
        if rightBuffer == nil || leftBuffer == nil {
            return ("","","",nil,nil,nil)
        } else {
            var newPrim: String? = nil
            if (components[2] == "=" || components[2] == "<>") && bufferOrder[leftBuffer!]! >= bufferOrder[rightBuffer!]! {
                if (bufferOrder[leftBuffer!]! > bufferOrder[rightBuffer!]!) || (Int(components[1]) > Int(components[4])) {
                    let tmp = rightBuffer
                    rightBuffer = leftBuffer
                    leftBuffer = tmp
                    let tmp2 = components[1]
                    components[1] = components[4]
                    components[4] = tmp2
                    newPrim = components[3] + components[1] + components[2] + components[0] + components[4]
                }
            }
            return (leftBuffer!,"slot" + components[1],components[2],rightBuffer!, "slot" + components[4],newPrim)
        }
    }
}

class Prim:NSObject, NSCoding {
    let lhsBuffer: String?
    let lhsSlot: String?
    let rhsBuffer: String? // Can be nil
    let rhsSlot: String?
    let op: String
    unowned let model: Model
    let name: String
    
    override var description: String {
        get {
            return name
        }
    }
    
    init(name: String, model: Model) {
        self.name = name
        self.model = model
        (lhsBuffer,lhsSlot,op,rhsBuffer,rhsSlot,_) = parseName(name)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard let model = aDecoder.decodeObject(forKey: "model") as? Model,
            let name = aDecoder.decodeObject(forKey: "name") as? String
            else { return nil }
        self.init(name: name, model: model)
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(self.model, forKey: "model")
        coder.encode(self.name, forKey: "name")
    }
    
    /**
    Carry out the PRIM, either by checking its condition or by performing its action. 
    In the case of an action to an empty buffer, an empty fact chunk is created in that buffer.
    - parameter condition: Is this a condition or action Prim? Relevant for push actions
    - returns: a Bool to indicate success
    */
    func fire(condition: Bool) -> Bool {
//        print("Checking PRIM \(name)")
        let lhsVal = (lhsBuffer == nil) || (lhsSlot == nil) ? nil : model.buffers[lhsBuffer!]?.slotValue(lhsSlot!)
//        lhsBuffer! == "operator" ? model.buffers[lhsBuffer!]?.slotValue(lhsSlot!) : model.formerBuffers[lhsBuffer!]?.slotValue(lhsSlot!)
        
        switch op {
        case "=":
            if rhsBuffer == nil {
                return lhsVal == nil
            } else if lhsVal == nil {
                return false
            }
            let rhsVal = model.buffers[rhsBuffer!]?.slotValue(rhsSlot!)
            if lhsBuffer != nil && lhsBuffer! == "temporal" && lhsSlot != nil && lhsSlot! == "slot1" {
                return rhsVal == nil ? false : model.temporal.compareTime(compareValue: rhsVal!.number())
            }
            if rhsBuffer != nil && rhsBuffer! == "temporal" && rhsSlot != nil && rhsSlot! == "slot1" {
                return lhsVal == nil ? false : model.temporal.compareTime(compareValue: lhsVal!.number())
            }
            return rhsVal == nil ? false : lhsVal!.isEqual(rhsVal!)
        case "<>":
            if rhsBuffer == nil {
                return lhsVal != nil
            } else if lhsVal == nil {
                return false
            }
            let rhsVal = model.buffers[rhsBuffer!]?.slotValue(rhsSlot!)
            return rhsVal == nil ? false : !lhsVal!.isEqual(rhsVal!)
        case "->":
            if lhsBuffer != nil && lhsVal == nil { // We cannot transfer nil from one slot to another
                return false }
            if lhsSlot == nil && rhsSlot == "slot0" && rhsBuffer != nil { // Clearing a Buffer
                model.buffers[rhsBuffer!] = nil
                if rhsBuffer! == "imaginal" {
                    model.imaginal.moveWMtoDM() // If the imaginal buffer is cleared we move all of WM to DM
                    model.imaginal.hasToDoAction = true // We have to set time aside for an imaginal action
                }
            }
            if lhsSlot == nil && model.buffers[rhsBuffer!] != nil && model.buffers[rhsBuffer!]!.slotvals[rhsSlot!] != nil { // We want to put nil to replace an existing slot value
                model.buffers[rhsBuffer!]!.slotvals[rhsSlot!] = nil
                return true
            }
//            if rhsBuffer == nil || lhsVal == nil {return false}
            if model.buffers[rhsBuffer!] == nil {
                let chunk = model.generateNewChunk(rhsBuffer!)
                chunk.setSlot("isa",value: "fact")
                model.buffers[rhsBuffer!] = chunk
                if rhsBuffer! == "imaginal" {
                    model.imaginal.addChunk(chunk: chunk)
                }
            }
            if lhsVal == nil {
                if rhsBuffer! == "imaginalN" {
                    model.buffers[rhsBuffer!]!.setSlot(rhsSlot!, value: "nil")
                }
                return true
            }
            // If we copy something to slot0 of a buffer chunk we replace the whole chunk with the new chunk
            if rhsSlot! == "slot0" {
                if let newChunk = lhsVal?.chunk() {
                    if rhsBuffer! == "imaginal", let currentImaginal = model.buffers["imaginal"] {
                        _ = model.dm.addToDM(chunk: currentImaginal)
                        if currentImaginal.parent != nil {
                            newChunk.parent = currentImaginal.parent
                            let parentChunk = model.imaginal.chunks[currentImaginal.parent!]!
                            for (slot,value) in parentChunk.slotvals {
                                if value.chunk() != nil && value.chunk() == currentImaginal {
                                    parentChunk.setSlot(slot, value: newChunk)
                                }
                            }
                        }
                    }
                    model.buffers[rhsBuffer!] = newChunk
                } else {
                    return false
                }
            }
            model.buffers[rhsBuffer!]!.setSlot(rhsSlot!, value: lhsVal!)
            return true
        case ">>":
            switch rhsBuffer! {
                case "imaginal":
                    return model.imaginal.push(slot: rhsSlot!, condition: condition)
//                case "goal":
//                    return model.goalPush(slot: rhsSlot!)
                case "retrievalH":
                    return model.dm.push(slot: rhsSlot!)
                case "input":
                    return model.action.push(slot: rhsSlot!)
            default: return false
            }
        case "<<":
            switch lhsBuffer! {
            case "imaginal":
                return model.imaginal.pop()
//            case "goal":
//                return model.goalPop()
            case "retrievalH":
                return model.dm.pop()
            case "input":
                return model.action.pop()
            default: return false
            }
        default: return false
        }
        
    }
    
    /**
    Test whether an action PRIM is applicable, if not return false
    This is the case if the lhs part doesn't resolve to nil
    */
    func testFire() -> Bool {
        if op == ">>" || op == "<<" { return true }
        if lhsSlot == nil { return true } else {
            let lhsVal = model.buffers[lhsBuffer!]?.slotValue(lhsSlot!)
            return lhsVal != nil
        }
    }
    
    
    
}
