//
//  PRScreen.swift
//  PRIMs
//
//  Created by Niels Taatgen on 5/11/15.
//  Copyright (c) 2015 Niels Taatgen. All rights reserved.
//

import Foundation

class PRScreen {
    /// Name of the screen
    let name: String
    /// Each Screen has a single object that acts as a container for all the "real" objects
    var object: PRObject! = nil
    /// Dictionary with action transitions to other screens
    var transitions: [String:PRScreen] = [:]
    /// Time of the next transition, if any
    var timeTransition: Double? = nil
    /// Screen to switch to after time has elapsed
    var timeTarget: PRScreen? = nil
    /// Is the transitiontime absolute (relative to start of trial), or relative (to the moment this screen came on)
    var timeAbsolute: Bool = true
    /// What is the parent of the object we are currently attending?
    var currentParentObject: PRObject? = nil
    /// What is the object we are currently attending?
    var currentAttendedObject: PRObject? {
        get {
            if currentParentObject == nil || currentParentObject!.attended >= currentParentObject!.subObjects.count {
                return nil
            } else  {
                return currentParentObject!.subObjects[currentParentObject!.attended]
            }
            
        }
    }
    
    init(name: String) {
        self.name = name
    }
    
    func start() {
        currentParentObject = object
        focusFirst()
    }
    
    func focusFirst() {
        if currentParentObject != nil {
            currentParentObject!.attended = 0
        }
    }
    
    func focusNext() {
        if currentParentObject != nil {
            currentParentObject!.attended++
        }
    }
    
    
    func focusDown() {
        currentParentObject = currentAttendedObject
        if currentParentObject != nil {
            currentParentObject!.attended = 0
        }
    }
    
    func focusUp() {
        if currentParentObject != nil {
            currentParentObject = currentParentObject!.superObject
            focusNext()
        }
    }
    
    /**
    Generate a chunk that encodes the currently attended object. If no object is attended, return an error chunk. If no object is attended because there are no more objects in the current container, but the type of the objects in the container in slot1, and error in slot2
    
    :returns: A chunk
    */
    func current(model: Model) -> Chunk {
        if currentAttendedObject == nil && (currentParentObject == nil || currentParentObject!.subObjects.count == 0) {
            let result = model.generateNewChunk(s1: "perception")
            result.setSlot("isa", value: "fact")
            result.setSlot("slot1", value: "error")
            return result
        } else if currentAttendedObject == nil {
            let result = model.generateNewChunk(s1: "perception")
            result.setSlot("isa", value: "fact")
            result.setSlot("slot1", value: currentParentObject!.subObjects[0].attributes[0])
            result.setSlot("slot2", value: "error")
            return result
        } else {
            return currentAttendedObject!.chunk(model)
        }
        
    }
    
}