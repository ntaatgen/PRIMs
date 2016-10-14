//
//  PRScenario.swift
//  PRIMs
//
//  Created by Niels Taatgen on 5/12/15.
//  Copyright (c) 2015 Niels Taatgen. All rights reserved.
//

import Foundation

class PRScenario {
    /// What are the possible screens in the scenario?
    var screens: [String:PRScreen] = [:]
    /// What are the different inputs (variable bindings for objects)
    var inputs: [String:[String:String]] = [:]
    /// What is the current queue of inputs
    var trials: [String] = []
    /// What is the current screen?
    var currentScreen: PRScreen? = nil
    /// What is the start screen at the beginning of the scenario?
    var startScreen: PRScreen! = nil
    /// When is the next event due?
    var nextEventTime: Double? = nil
    /// Current inputs
    var currentInput: [String:String] = [:]
    /// The action that finalized the scenario
    var goalAction: [String] = []
    /// A script that runs the experiment. Replaces most of the above.
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

    func goStart(_ model: Model) {
        if !inputs.isEmpty && trials.isEmpty {
            for (name,_) in inputs {
                trials.append(name)
            }
            for i in 0..<trials.count {
                let randomPos = Int(arc4random_uniform(UInt32(trials.count)))
                let tmp = trials[randomPos]
                trials[randomPos] = trials[i]
                trials[i] = tmp
            }
        }
        if !inputs.isEmpty {
            currentInput = inputs[trials.remove(at: 0)]!
        } else {
            currentInput = [:]
        }
        currentScreen = startScreen
        currentScreen!.start()
        if currentScreen!.timeTransition != nil {
            if currentScreen!.timeAbsolute {
                nextEventTime =  model.startTime + currentScreen!.timeTransition!
            } else {
                nextEventTime = model.time + currentScreen!.timeTransition!
            }
        }
    }
    
    func makeSubstitutions(_ chunk: Chunk) -> Chunk {
        for (slot,value) in chunk.slotvals {
            if let substitution = currentInput[value.description] {
                chunk.setSlot(slot, value: substitution)
            }
        }
        return chunk
    }
    
    func current(_ model: Model) -> Chunk {
        return makeSubstitutions(currentScreen!.current(model))
    }
    
    func doAction(_ model: Model, action: String?, par1: String?) -> Chunk? {
        if action == nil { return nil }
        if let transition = currentScreen!.transitions[action!] {
            if script == nil {
                currentScreen = transition
                currentScreen!.start()
                if currentScreen!.timeTransition != nil {
                    if currentScreen!.timeAbsolute {
                        nextEventTime = model.startTime + currentScreen!.timeTransition!
                    } else {
                        nextEventTime = model.time + currentScreen!.timeTransition!
                    }
                } else {
                    nextEventTime = nil
                }
            }
        } else {
            switch action! {
            case "focusfirst","focus-first":
                currentScreen!.focusFirst()
            case "focusnext","focus-next":
                currentScreen!.focusNext()
            case "focusdown","focus-down":
                currentScreen!.focusDown()
            case "focusup","focus-up":
                currentScreen!.focusUp()
            case "attendfirst","attend-first":
                currentScreen!.attendFirst()
            case "attendrandom","attend-random":
                currentScreen!.attendRandom()
            case "attenddownrandom","attend-down-random":
                currentScreen!.attendDownRandom()
            case "attenduprandom","attend-up-random":
                currentScreen!.attendUpRandom()
            default: return nil
            }
        }
        let chunk = makeSubstitutions(currentScreen!.current(model))
        //        println("Doing action \(action) resulting in \(chunk)")
        return chunk
    }

    func makeTimeTransition(_ model: Model) {
        repeat {
            currentScreen = currentScreen!.timeTarget!
            currentScreen!.start()
            if currentScreen!.timeTransition != nil {
                if currentScreen!.timeAbsolute {
                    nextEventTime = model.startTime + currentScreen!.timeTransition!
                    
                } else {
                    nextEventTime = model.time + currentScreen!.timeTransition!
                }
            } else {
                nextEventTime = nil
            }
        } while nextEventTime != nil && nextEventTime! < model.time
        let chunk = makeSubstitutions(currentScreen!.current(model))
        model.buffers["input"] = chunk
        model.addToTrace("Switching to screen \(currentScreen!.name), next switch is \(nextEventTime)", level: 2)
        
    }
    
}
