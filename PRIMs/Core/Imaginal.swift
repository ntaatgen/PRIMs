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
    var autoClear = false // Now obsolete
    var chunks: [String:Chunk] = [:]
    /// Variable that records whether an imaginal action is needed
    var hasToDoAction: Bool = false
    /// Total extra time to carry out WM related actions
    var imaginalActionTime = 0.0
    init(model: Model) {
        self.model = model
    }

    func reset() {
        chunks = [:]
        imaginalActionTime = 0.0
    }
    
    func addChunk(chunk: Chunk) {
        chunks[chunk.name] = chunk
        chunk.startTime()
    }

    func moveWMtoDM() {
        var transDict: [String: String] = [:]
        print("Adding WM to DM")
        while !chunks.isEmpty {
            var removedAChunk = false
            for (_, chunk) in chunks {
                var noRefs = true
                for (_,value) in chunk.slotvals {
                    if let valueChunk = value.chunk(), chunks[valueChunk.name] != nil {
                        noRefs = false
                    }
                }
                if noRefs { // we found a chunk we can add
                    print("Adding \(chunk.name)")
                    for (slot, value) in chunk.slotvals {
                        if let valueName = value.chunk()?.name, let substitution = transDict[valueName] {
                            chunk.setSlot(slot, value: substitution)
//                            print("Substituted \(value.description) with \(substitution) in \(chunk.name)")
                        }
                    }
                    let newChunk = model.dm.addToDM(chunk: chunk)
                    if newChunk.name != chunk.name { // DM merged the chunk with an old chunk
                        print("Chunk is merged with \(newChunk.name)")
                        transDict[chunk.name] = newChunk.name
                    }
                    chunks[chunk.name] = nil // remove the chunk from WM
                    removedAChunk = true
                }
            }
            if !removedAChunk { // If there is some circularity in the remaining chunks, we cannot properly merge them, so we will just dump them all in DM and be done
                for (_,chunk) in chunks {
                    for (slot, value) in chunk.slotvals {
                        if let valueName = value.chunk()?.name, let substitution = transDict[valueName] {
                            chunk.setSlot(slot, value: substitution)
//                            print("Substituted \(value.description) with \(substitution) in \(chunk.name)")
                        }
                    }
                    _ = model.dm.addToDM(chunk: chunk)
                }
                chunks = [:]
            }
        }
        // Finally, we need to check the current buffers because they may still have references to the changed chunks
        for (_, chunk) in model.buffers {
            for (slot, value) in chunk.slotvals {
                if let valueName = value.chunk()?.name, let substitution = transDict[valueName] {
                    chunk.setSlot(slot, value: substitution)
//                    print("Substituted \(value.description) with \(substitution) in \(chunk.name)")
                }
            }
        }
    }
    
    func setParametersToDefault() {
        imaginalLatency = Imaginal.imaginalLatencyDefault
    }
    
    func action() -> Double {
        hasToDoAction = false
        if !model.silent {
            model.addToTrace("New imaginal chunk (latency = \(imaginalLatency.string(fractionDigits: 3)))", level: 2)
        }
        return imaginalLatency
    }
    
    /*
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
    */
    
    /**
        Carry out a "push" action on a chunk in the Imaginal buffer. If the content of the slot is nil, a new chunk is created and place into the slot. The existing chunk is added to DM.
        - parameter slot: The slot that should be pushed
        - parameter condition: if the push is part of a condition, it should not create new chunks
        - returns: Whether the push was successful
    */
    func push(slot: String, condition: Bool) -> Bool {
        
        if model.buffers["imaginal"] == nil {
            return false
        }

        let oldImaginal = model.buffers["imaginal"]!
        if let value = oldImaginal.slotvals[slot] {
            if let chunk = value.chunk() {
                if chunks[chunk.name] != nil {
                    chunks[oldImaginal.name] = oldImaginal
                    oldImaginal.addReference()
                    chunk.parent = oldImaginal.name
                    //                print("Setting parent of \(chunk.name) to \(oldImaginal.name)")
                    imaginalActionTime += model.dm.latency(chunk.activation())
                    model.addToTrace("Imaginal retrieval latency of \(chunk.name) is \(model.dm.latency(chunk.activation()).string(fractionDigits: 3))", level: 5)
                    model.buffers["imaginal"] = chunk
                    return true
                } else {
                    // chunk is already in declarative memory, so make a copy and put it in the buffer
                    if let dmChunk = model.dm.chunks[chunk.name]?.copyChunk() {
                        chunks[oldImaginal.name] = oldImaginal
                        oldImaginal.addReference()
                        dmChunk.parent = oldImaginal.name
                        dmChunk.startTime()
                        addChunk(chunk: dmChunk)
                        oldImaginal.setSlot(slot, value: dmChunk)
                        imaginalActionTime += model.dm.latency(chunk.activation())
                        model.addToTrace("Imaginal retrieval latency of \(chunk.name) is \(model.dm.latency(chunk.activation()).string(fractionDigits: 3))", level: 5)
                        model.buffers["imaginal"] = dmChunk
                        return true
                    } else {
                        return false // The chunk can't be found (shouldn't happen)
                    }
                }
            } else {
                return false // there is a String or a number in that slot
            }
        } else if !condition { // Create a new Chunk in the slot and then move to it
            let newImaginal = Chunk(s: model.generateName("wm"), m: model)
            newImaginal.setSlot("isa", value: "fact")
            newImaginal.startTime()
            addChunk(chunk: newImaginal)
            oldImaginal.setSlot(slot, value: newImaginal)
            chunks[oldImaginal.name] = oldImaginal
            oldImaginal.addReference()
//            let oldWMchunk = model.dm.addOrUpdate(chunk: oldImaginal)
//            if oldImaginal.name != oldWMchunk.name {
//                print("Changed chunk \(oldImaginal.name) into \(oldWMchunk.name)")
//            }
            newImaginal.parent = oldImaginal.name
            imaginalActionTime += imaginalLatency
            model.addToTrace("New imaginal chunk \(newImaginal.name) latency is \(imaginalLatency)", level: 5)
            
//            print("Setting parent of \(newImaginal.name) to \(oldImaginal.name)")
            model.buffers["imaginal"] = newImaginal
//            hasToDoAction = true
            return true
        }
        else { return false }
    }


    /**
        Carry out a "pop" action on the Imaginal buffer: restore the previous element in the tree, assuming it exists.
        - returns: Whether the pop was successful
    */
    func pop() -> Bool {
        if let parent = model.buffers["imaginal"]?.parent {
            let currentImChunk = model.buffers["imaginal"]!
            chunks[currentImChunk.name] = currentImChunk
            currentImChunk.addReference()
//            let imChunkInDM = model.dm.addOrUpdate(chunk: currentImChunk)
            let parentChunk = chunks[parent]!
//            if currentImChunk.name != imChunkInDM.name {
//                print("Changing \(currentImChunk.name) in \(parentChunk.name) into \(imChunkInDM.name)")
//                for (slot,value) in parentChunk.slotvals {
//                    if value.description == currentImChunk.name {
//                        parentChunk.setSlot(slot, value: imChunkInDM)
//                    }
//                }
//                parentChunk = model.dm.eliminateDuplicateChunkAlreadyInDM(chunk: parentChunk)
//            }
            imaginalActionTime += model.dm.latency(parentChunk.activation())
            model.addToTrace("Imaginal retrieval latency of \(parentChunk.name) is \(model.dm.latency(parentChunk.activation()).string(fractionDigits: 3))", level: 5)
            if model.dm.latency(parentChunk.activation()) > 1.0 {
                print("WM dump")
                print("Parent is \(parentChunk.name)")
                for (_,chunk) in chunks {
                print(chunk)
                    print("BL Activation \(chunk.baseLevelActivation()) Activation \(chunk.activation())")
                    for (id,(act,number)) in chunk.assocs {
                        print("Assoc with \(id) is \(act) , \(number)")
                    }
                    print("Spreading activation is \(chunk.spreadingActivation()) noise = \(chunk.calculateNoise())")
                }
            }
            
            model.buffers["imaginal"] = parentChunk
            return true
        } else {
//            print("Parent slot is empty")
            return false
        }
    }
    
    
    
}
