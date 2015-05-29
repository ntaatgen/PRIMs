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
    /// What is the current screen?
    var currentScreen: PRScreen? = nil
    /// What is the start screen at the beginning of the scenario?
    var startScreen: PRScreen! = nil
    /// When is the next event due?
    var nextEventTime: Double? = nil
    
    func goStart(model: Model) {
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
    
    func current(model: Model) -> Chunk {
        return currentScreen!.current(model)
    }
    
    func doAction(model: Model, action: String?, par1: String?) -> Chunk? {
        if action == nil { return nil }
        if let transition = currentScreen!.transitions[action!] {
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
        } else {
            switch action! {
            case "focusfirst":
                currentScreen!.focusFirst()
            case "focusnext":
                currentScreen!.focusNext()
            case "focusdown":
                currentScreen!.focusDown()
            case "focusup":
                currentScreen!.focusUp()
            default: return nil
            }
        }
        let chunk = currentScreen!.current(model)
        //        println("Doing action \(action) resulting in \(chunk)")
        return chunk
    }

    func makeTimeTransition(model: Model) {
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
        let chunk = currentScreen!.current(model)
        model.buffers["input"] = chunk
        model.addToTrace("Switching to screen \(currentScreen!.name), next switch is \(nextEventTime)")
        
    }
    
}