//
//  ConditionPrim.swift
//  
//
//  Created by Niels Taatgen on 4/17/15.
//
//

import Foundation

let bufferMappingC = ["V":"input","WM":"imaginal","G":"goal","C":"operator","AC":"action","RT":"retrievalH","GC":"constants"]
let bufferMappingA = ["V":"input","WM":"imaginalN","G":"goal","C":"operator","AC":"action","RT":"retrievalR","GC":"constants"]

/** 
This function takes a string that represents a PRIM, and translaters it its components
Result is a five-tuple with left-buffer-name left-buffer-slot, operator, right-buffer-name and right-buffer-slot
*/
func parseName(name: String) -> (String,String,String,String?,String?) {
    var components: [String] = []
    var component = ""
    var prevComponentCat = 1
    for ch in name {
        var componentCat: Int
        switch ch {
        case "A"..."Z":  componentCat = 1
        case "0"..."9":  componentCat = 2
        case "<",">","=","-":  componentCat = 3
        default:  componentCat = -1
        }
        if prevComponentCat == componentCat {
            component += String(ch)
        } else {
            components.append(component)
            component = String(ch)
        }
        prevComponentCat = componentCat
    }
    components.append(component)
    if components.count < 4 || (components[3] != "nil" && (components.count == 4 || bufferMappingC[components[3]] == nil)) || bufferMappingC[components[0]] == nil {
        println("Error in parsing \(name)")
        return ("","","",nil,nil)
    } else if components[3] == "nil" {
        return (bufferMappingC[components[0]]!,"slot" + components[1],components[2],nil,nil)
    } else {
        let rightBuffer = (components[2] == "->") ? bufferMappingA[components[3]]! : bufferMappingC[components[3]]!
        return (bufferMappingC[components[0]]!,"slot" + components[1],components[2],rightBuffer, "slot" + components[4])
    }
}

class Prim:Printable {
    let lhsBuffer: String
    let lhsSlot: String
    let rhsBuffer: String? // Can be nil
    let rhsSlot: String?
    let op: String
    let model: Model
    let name: String
    
    var description: String {
        get {
            return name
        }
    }
    
    init(name: String, model: Model) {
        self.name = name
        self.model = model
        (lhsBuffer,lhsSlot,op,rhsBuffer,rhsSlot) = parseName(name)
    }
    
    
    
    /**
    Carry out the PRIM, either by checking its condition or by performing its action. Returns a Bool to indicate success
    In the case of an action to an empty buffer, an empty fact chunk is created in that buffer.
    */
    func fire() -> Bool {
        let lhsVal = model.buffers[lhsBuffer]?.slotValue(lhsSlot)
        switch op {
        case "=":
            if rhsBuffer == nil {
                return lhsVal == nil
            } else if lhsVal == nil {
                return false
            }
            let rhsVal = model.buffers[rhsBuffer!]?.slotValue(rhsSlot!)
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
            if rhsBuffer == nil || lhsVal == nil {return false} 
            if model.buffers[rhsBuffer!] == nil {
                let chunk = model.generateNewChunk(s1: rhsBuffer!)
                chunk.setSlot("isa",value: "fact")
                model.buffers[rhsBuffer!] = chunk
            }
            model.buffers[rhsBuffer!]!.setSlot(rhsSlot!, value: lhsVal!)
            return true
        default: return false
        }
        
    }
    
    /**
    Test whether an action PRIM is applicable, if not return false
    This is the case if the lhs part doesn't resolve to nil
    */
    func testFire() -> Bool {
        let lhsVal = model.buffers[lhsBuffer]?.slotValue(lhsSlot)
        return lhsVal != nil
    }



}