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
    var autoClear = true
    
    init(model: Model) {
        self.model = model
    }
    
    deinit {
        print("Imaginal is deinitialized")
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
                model.addToTrace("New imaginal chunk \(newImaginal.name)  (latency = \(imaginalLatency))", level: 2)
                model.dm.addToDM(oldImaginal)
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
        newImaginal.setSlot("isa", value: "fact")
        model.buffers["imaginal"] = newImaginal
        model.addToTrace("New imaginal chunk \(newImaginal.name)  (latency = \(imaginalLatency))", level: 2)
        return imaginalLatency
    }
}