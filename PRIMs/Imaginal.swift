//
//  Imaginal.swift
//  PRIMs
//
//  Created by Niels Taatgen on 4/27/15.
//  Copyright (c) 2015 Niels Taatgen. All rights reserved.
//

import Foundation

class Imaginal {
    var imaginalLatency = 0.2
    let model: Model
    var autoClear = true
    
    init(model: Model) {
        self.model = model
    }
    
    func action() -> Double {
        let newImaginal = model.buffers["imaginalN"]!
        model.buffers["imaginalN"] = nil
        if let oldImaginal = model.buffers["imaginal"] {
            var overlap = false
            for (slot,value) in newImaginal.slotvals {
                if slot != "isa" && oldImaginal.slotvals[slot] != nil {
                    overlap = true
                }
            }
            if overlap && autoClear {
                newImaginal.setSlot("isa", value: oldImaginal.slotvals["isa"]!)
                model.buffers["imaginal"] = newImaginal
                model.addToTrace("New imaginal chunk \(newImaginal.name)")
                model.dm.addToDM(oldImaginal)
                return imaginalLatency
            } else {
                for (slot,value) in newImaginal.slotvals {
                    oldImaginal.setSlot(slot, value: value)
                }
                return 0.0
            }
        }
        newImaginal.setSlot("isa", value: "fact")
        model.buffers["imaginal"] = newImaginal
        model.addToTrace("New imaginal chunk \(newImaginal.name)")
        return imaginalLatency
    }
}