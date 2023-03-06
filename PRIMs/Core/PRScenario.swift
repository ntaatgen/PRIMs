//
//  PRScenario.swift
//  PRIMs
//
//  Created by Niels Taatgen on 5/12/15.
//  Copyright (c) 2015 Niels Taatgen. All rights reserved.
//

import Foundation

class PRScenario {
     /// When is the next event due?
    var nextEventTime: Double? = nil
    /// Current inputs
    var currentInput: [String:String] = [:]
    /// The script that runs the experiment.
    var script: Script?
    /// A script that has to be run as initialization of the model
    var initScript: Script?

    var inputMappingForTrace: [String] {
        get {
            var mapping: [String] = ["void","void","void","void","void"]
            for i in 0..<5 {
                let index = "?\(i)"
                if let value = self.currentInput[index] {
                    mapping[i] = value
                }
            }
            return mapping
        }
    }

}
