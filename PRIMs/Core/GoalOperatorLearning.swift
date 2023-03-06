//
//  GoalOperatorLearning.swift
//  PRIMs
//
//  Created by Niels Taatgen on 7/14/15.
//  Copyright (c) 2015 Niels Taatgen. All rights reserved.
//


// This is an experimental change to how activation is calculated for 
// operators. If you want to use this, include it in the target
// and comment out the activation function in Chunk.swift
//

import Foundation

extension Chunk {
    
    func spreadingCount() -> Double {
        let goal = model.buffers["goal"]?.slotvals["slot1"]
        if goal == nil { return 1.0 }
        let assoc = self.assocs[goal!.description]
        if assoc == nil { return 1.0 } else
        {
//            println("\(name) assocs \(assoc!.1)")
            return Double(assoc!.1)
        }
    }
    
    func activation() -> Double {
        if creationTime == nil {return 0}
        if type != "operator" {
        return  self.baseLevelActivation()
            + self.spreadingActivation() + calculateNoise()
        } else {
            let count = spreadingCount()
            return (1 * self.baseLevelActivation() + (1 + count) * self.spreadingActivation()) / ( 2 + count) + calculateNoise()
        }
        
    }
    
    
}