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
    weak var timeTarget: PRScreen? = nil
    /// Is the transitiontime absolute (relative to start of trial), or relative (to the moment this screen came on)
    var timeAbsolute: Bool = true
    /// What is the parent of the object we are currently attending?
    weak var currentParentObject: PRObject? = nil
    /// What is the object we are currently attending?
    weak var currentAttendedObject: PRObject? {
        get {
            if currentParentObject == nil || currentParentObject!.attended >= currentParentObject!.subObjects.count {
                return nil
            } else  {
                return currentParentObject!.subObjects[currentParentObject!.attended]
            }
            
        }
    }
    
    /* 
        The objects form a tree, with 'object' as root. At any time, the representation is as follows: currenParentObject represents the
        parent of the currently attended object. The parent has an attended index that points to which object is currently attended within the
        parent's list.
        Each object also has an selfAttended value, which indicates whether the object has been attended at any point.
    
    */
    init(name: String) {
        self.name = name
    }

    /**
     Reset the screen, and focus on the first element within the current screen
    */
    func start() {
        unattend()
        currentParentObject = object
        object.attend()
        focusFirst()
    }
    
    /**
     Focus on the first object within the current focus
    */
    func focusFirst() {
        if currentParentObject != nil {
            currentParentObject!.attended = 0
        }
        if let obj = currentAttendedObject {
            obj.attend()
        }
    }
    
    /**
     Focus on the next object within the current focus
     */
    func focusNext() {
        if currentParentObject != nil {
            currentParentObject!.attended += 1
        }
        if let obj = currentAttendedObject {
            obj.attend()
        }
    }
    
    /**
     Shift focus to the currently attended object
     */
    func focusDown() {
        currentParentObject = currentAttendedObject
        focusFirst()
    }
    
    /**
     Shift focus to superobject of the current focus
    */
    func focusUp() {
        if currentParentObject != nil {
            currentParentObject = currentParentObject!.superObject
            focusNext()
        }
    }
    
    /**
     Attend the first unattended item within the current focus
    */
    func attendFirst() {
        if currentParentObject == nil {
            return
        }
        var i = 0
        while i < currentParentObject!.subObjects.count && currentParentObject!.subObjects[i].selfAttended {
            i += 1
        }
        currentParentObject!.attended = i
        if let obj = currentAttendedObject {
            obj.attend()
        }
    }
    
    /**
     Attend a random unattended item within the current focus
    */
    func attendRandom() {
        if currentParentObject == nil {
            return
        }
        var sum = 0  // How many unattended object are there?
        for obj in currentParentObject!.subObjects {
            if !obj.selfAttended {
                sum += 1
            }
        }
        if sum == 0 {
            currentParentObject!.attended = currentParentObject!.subObjects.count
            return
        }
        var randomPos = Int(arc4random_uniform(UInt32(sum))) // Pick a random object
        var i = -1
        repeat {
            i += 1
            while currentParentObject!.subObjects[i].selfAttended { // find the next unattended object
                i += 1
            }
            randomPos -= 1
        } while randomPos > 0
        currentParentObject!.attended = i
        if let obj = currentAttendedObject {
            obj.attend()
        }

    }
    
    /**
     Shift focus to the currently attended object, and attend a random subobject
     */
    func attendDownRandom() {
        currentParentObject = currentAttendedObject
        attendRandom()
    }
    
    /**
     Shift focus to the currently attended object, and attend a random subobject
     */
    func attendUpRandom() {
        if currentParentObject != nil {
            currentParentObject = currentParentObject!.superObject
            attendRandom()
        }
    }
    
    /**
    Set attention status of all objects on the screen to false
    */
    func unattend() {
        object.unattend()
    }
    
    /**
    Generate a chunk that encodes the currently attended object. If no object is attended, return an error chunk. If no object is attended because there are no more objects in the current container, but the type of the objects in the container in slot1, and error in slot2
    
    - returns: A chunk
    */
    func current(_ model: Model) -> Chunk {
        if currentAttendedObject == nil && (currentParentObject == nil || currentParentObject!.subObjects.count == 0) {
            let result = model.generateNewChunk("perception")
            result.setSlot("isa", value: "fact")
            result.setSlot("slot1", value: "error")
            return result
        } else if currentAttendedObject == nil {
            let result = model.generateNewChunk("perception")
            result.setSlot("isa", value: "fact")
            result.setSlot("slot1", value: currentParentObject!.subObjects[0].attributes[0])
            result.setSlot("slot2", value: "error")
            return result
        } else {
            return currentAttendedObject!.chunk(model)
        }
        
    }
    
}
