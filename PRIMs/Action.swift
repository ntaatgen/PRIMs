//
//  Action.swift
//  PRIMs
//
//  Created by Niels Taatgen on 4/28/15.
//  Copyright (c) 2015 Niels Taatgen. All rights reserved.
//

import Foundation

class Action {
    let model: Model
    var sayLatency = 0.3
    var subvocalizeLatency = 0.3
    static let nothing = "nothing"
    init(model: Model) {
        self.model = model
    }
    
    func action() -> Double {
        let actionChunk = model.buffers["action"]!
        var latency = 0.05
        model.buffers["action"] = nil
        let ac = actionChunk.slotvals["slot1"]?.description
        let par1 = actionChunk.slotvals["slot2"]?.description
        if ac != nil {
            switch ac! {
            case "say":
                model.addToTrace("Saying \(par1 == nil ? Action.nothing : par1!)")
                latency = sayLatency
            case "subvocalize":
                model.addToTrace("Subvocalizing \(par1 == nil ? Action.nothing : par1!)")
                latency = subvocalizeLatency
            default: model.addToTrace("\(ac!)-ing \(par1 == nil ? Action.nothing : par1!)")
            }
        }
        return latency
    }
    
}