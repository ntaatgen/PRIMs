//
//  PRScenario.swift
//  PRIMs
//
//  Created by Niels Taatgen on 5/12/15.
//  Copyright (c) 2015 Niels Taatgen. All rights reserved.
//

import Foundation

class PRScenario {
    var screens: [String:PRScreen] = [:]
    var currentScreen: PRScreen? = nil
    var startScreen: PRScreen! = nil
    
    func goStart() {
        currentScreen = startScreen
        currentScreen!.start()
    }
    
    func current(model: Model) -> Chunk {
        return currentScreen!.current(model)
    }
    
    func doAction(model: Model, action: String?, par1: String?) -> Chunk? {
        if action == nil { return nil }
        switch action! {
        case "focus-first":
            currentScreen!.focusFirst()
        case "focus-next":
            currentScreen!.focusNext()
        case "focus-down":
            currentScreen!.focusDown()
        case "focus-up":
            currentScreen!.focusUp()
        default: return nil
        }
        let chunk = currentScreen!.current(model)
//        println("Doing action \(action) resulting in \(chunk)")
        return chunk
    }

    
}