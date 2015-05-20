//
//  PRScreen.swift
//  PRIMs
//
//  Created by Niels Taatgen on 5/11/15.
//  Copyright (c) 2015 Niels Taatgen. All rights reserved.
//

import Foundation

class PRScreen {
    let name: String
    var object: PRObject! = nil
    var transitions: [String:PRScreen] = [:]
    var timeTransition: Double? = nil
    var timeTarget: PRScreen? = nil
    var timeAbsolute: Bool = true
    
    var currentParentObject: PRObject? = nil
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
        currentParentObject!.attended = 0
    }
    
    func focusNext() {
        currentParentObject!.attended++
    }
    
    
    func focusDown() {
        currentParentObject = currentAttendedObject
        currentParentObject!.attended = 0
        
    }
    
    func focusUp() {
        currentParentObject = currentParentObject!.superObject
        focusNext()
    }
    
    
    func current(model: Model) -> Chunk {
        if currentAttendedObject == nil && currentParentObject == nil {
            let result = model.generateNewChunk(s1: "perception")
            result.setSlot("isa", value: "fact")
            result.setSlot("slot1", value: "error")
            return result
        } else if currentAttendedObject == nil {
            let result = model.generateNewChunk(s1: "perception")
            result.setSlot("isa", value: "fact")
            result.setSlot("slot1", value: currentParentObject!.attributes[0])
            result.setSlot("slot2", value: "error")
            return result
        } else {
            return currentAttendedObject!.chunk(model)
        }
        
    }
    
}