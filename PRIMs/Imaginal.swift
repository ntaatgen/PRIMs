//
//  Imaginal.swift
//  PRIMs
//
//  Created by Niels Taatgen on 4/27/15.
//  Copyright (c) 2015 Niels Taatgen. All rights reserved.
//

import Foundation

class Imaginal {
    static let imaginalLatencyDefault = 0.2
    var imaginalLatency = imaginalLatencyDefault
    unowned let model: Model
    /// Do we automatically move the Chunk to DM if an existing slot is modified? No more in this new version!
    var autoClear = false
    
    init(model: Model) {
        self.model = model
    }
    

    func setParametersToDefault() {
        imaginalLatency = Imaginal.imaginalLatencyDefault
    }
    
    func action() -> Double {
        let newImaginal = model.buffers["imaginalN"]!
        model.buffers["imaginalN"] = nil
        if let oldImaginal = model.buffers["imaginal"] {
            var overlap = false
            for (slot,_) in newImaginal.slotvals {
                if slot != "isa" && oldImaginal.slotvals[slot] != nil {
                    overlap = true
                }
            }
            if overlap && autoClear {
                newImaginal.setSlot("isa", value: oldImaginal.slotvals["isa"]!)
                for (slot,value) in newImaginal.slotvals {
                    if value.description == "nil" {
                        newImaginal.slotvals[slot] = nil
                    }
                }
                model.buffers["imaginal"] = newImaginal
                if !model.silent {
                    model.addToTrace("New imaginal chunk \(newImaginal.name)  (latency = \(imaginalLatency))", level: 2)
                }
                _ = model.dm.addToDM(chunk: oldImaginal)
                return imaginalLatency
            } else {
                for (slot,value) in newImaginal.slotvals {
                    if value.description == "nil" {
                        oldImaginal.slotvals[slot] = nil
                    } else {
                        oldImaginal.setSlot(slot, value: value)
                    }
                }
                return 0.0
            }
        }
        for (slot,value) in newImaginal.slotvals {
            if value.description == "nil" {
                newImaginal.slotvals[slot] = nil
            }
        }
        newImaginal.setSlot("isa", value: "fact")
        model.buffers["imaginal"] = newImaginal
        if !model.silent {
            model.addToTrace("New imaginal chunk \(newImaginal.name)  (latency = \(imaginalLatency))", level: 2)
        }
        return imaginalLatency
    }
    
    /**
        Carry out a "push" action on a chunk in the Imaginal buffer. If the content of the slot is nil, a new chunk is created and place into the slot. The existing chunk is added to DM.
        - returns: Whether the push was successful
    */
    func push(slot: String) -> Bool {
        if model.buffers["imaginal"] == nil {
            return false
        }
        let oldImaginal = model.buffers["imaginal"]!
        if let value = oldImaginal.slotvals[slot] {
            if let chunk = value.chunk() {
                let oldWMchunk = model.dm.addOrUpdate(chunk: oldImaginal) // If the chunk in Imaginal is not yet in DM, add it.
                chunk.parent = oldWMchunk.name
                model.buffers["imaginal"] = chunk
                return true
            } else {
                return false // there is a String or a number in that slot
            }
        } else { // Create a new Chunk in the slot and then move to it
            let newImaginal = Chunk(s: model.generateName("wm"), m: model)
            newImaginal.setSlot("isa", value: "fact")
            oldImaginal.setSlot(slot, value: newImaginal)
            let oldWMchunk = model.dm.addOrUpdate(chunk: oldImaginal)
            newImaginal.parent = oldWMchunk.name
            model.buffers["imaginal"] = newImaginal
            return true
            
        }
    }
    /** Carry out a "pop" action on the Imaginal buffer: restore the previous element in the tree, assuming it exists.
        - returns: Whether the pop was successful
    */
    func pop() -> Bool {
        if let parent = model.buffers["imaginal"]?.parent {
            let currentImChunk = model.buffers["imaginal"]!
            let imChunkInDM = model.dm.addOrUpdate(chunk: currentImChunk)
            var parentChunk = model.dm.chunks[parent]!
            if currentImChunk.name != imChunkInDM.name {
                for (slot,value) in parentChunk.slotvals {
                    if value.description == currentImChunk.name {
                        parentChunk.setSlot(slot, value: imChunkInDM)
                    }
                }
                parentChunk = model.dm.eliminateDuplicateChunkAlreadyInDM(chunk: parentChunk)
            }
            model.buffers["imaginal"] = parentChunk
            return true
        } else {
            return false
        }
    }
    
    
    
}
