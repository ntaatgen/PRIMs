//
//  ScriptFunctions.swift
//  PRIMs
//
//  Created by Niels Taatgen on 1/12/16.
//  Copyright © 2016 Niels Taatgen. All rights reserved.
//

import Foundation

let scriptFunctions: [String:([Factor], Model?) throws -> (result: Factor?, done: Bool, cont:Bool)] =
    ["screen": setScreen,
     "random": randIntNumber,
        "time": modelTime,
     "run-until-action": runUntilAction,
    "run-relative-time": runRelativeTime,
        "run-until-relative-time-or-action": runRelativeTimeOrAction,
     "print": printArg,
    "trial-end": trialEnd,
    "issue-reward": issueReward,
    "shuffle": shuffle]



/// Things that can be set
// model.scenario.nextEventTime: time at which the script continues
// model.scenario.currentScreen: screen we are working on

func setScreen(content: [Factor], model: Model?) throws -> (result: Factor?, done: Bool, cont: Bool) {
    let screen = PRScreen(name: "run-time")
    let rootObject = PRObject(name: "card", attributes: ["card"], superObject: nil)
    screen.object = rootObject
    var attributes: [String] = []
    for obj in content {
        switch (obj) {
        case .Str(let s):
            attributes.append(s)
        case .IntNumber(let num):
            attributes.append(String(num))
        case .RealNumber(let num):
            attributes.append(String(num))
        default:
            throw RunTimeError.errorInFunction("Wrong argument in screen")
        }
    }
    let subObject = PRObject(name: model!.generateName("object"), attributes: attributes, superObject: rootObject)
    rootObject.subObjects.append(subObject)
    model!.scenario.currentScreen = screen
    screen.start()
    model!.buffers["input"] = model!.scenario.current(model!)
    return (nil, true, true)
}

/**
    Return the current time in the model
 */
func modelTime(content: [Factor], model: Model?) throws -> (result: Factor?, done: Bool, cont: Bool) {
    return (Factor.RealNumber(model!.time), true, true)
}

/** 
    Print one or more values
*/
 func printArg(content: [Factor], model: Model?) throws -> (result: Factor?, done: Bool, cont: Bool) {
    var s: String = ""
    for arg in content {
        s += arg.description + " "
    }
    model?.addToTraceField(s)
    return (nil, true, true)
}

/**
   Generate a random number integer between 0 and the argument (exclusive)
*/
func randIntNumber(content: [Factor], model: Model?)  throws -> (result: Factor?, done: Bool, cont:Bool) {
    guard content.count == 1 else { throw RunTimeError.invalidNumberOfArguments }
    switch content[0] {
    case .IntNumber(let num):
        guard num >= 0 else { throw RunTimeError.errorInFunction("Negative argument in random") }
        let result = Int(arc4random_uniform(UInt32(num)))
        return (Factor.IntNumber(result), true, true)
    default:
        throw RunTimeError.errorInFunction("Call of random without Integer argument")
    }
}

/**
    Put the items of the given array in random order
*/
func shuffle(content: [Factor], model: Model?)  throws -> (result: Factor?, done: Bool, cont:Bool) {
    guard content.count == 1 else { throw RunTimeError.invalidNumberOfArguments }
    switch content[0] {
    case .Arr(let a):
        var newArray: [Expression] = []
        var oldArray = a.elements
        while oldArray.count > 0 {
            let index = Int(arc4random_uniform(UInt32(oldArray.count)))
            newArray.append(oldArray[index])
            oldArray.removeAtIndex(index)
        }
        return (Factor.Arr(ScriptArray(elements: newArray)), true, true)
    default: throw RunTimeError.errorInFunction("Trying to shuffle a non-array")
    }
}

/**
    Ends a trial: adds a line to the data, stores the result for the graph,
    initialized the model for a new trial
*/
func trialEnd(content: [Factor], model: Model?) throws -> (result: Factor?, done: Bool, cont:Bool) {
    if let imaginalChunk = model!.buffers["imaginal"] {
        model!.dm.addToDM(imaginalChunk)
    }
//    model!.running = false
    model!.resultAdd(model!.time - model!.startTime)
    let dl = DataLine(eventType: "trial-end", eventParameter1: "success", eventParameter2: "void", eventParameter3: "void", inputParameters: model!.scenario.inputMappingForTrace, time: model!.time - model!.startTime)
    model!.outputData.append(dl)
    model!.initializeNextTrial()
    return(nil, true, false)
}

/**
  Run the model until it takes the action specified
*/
func runUntilAction(content: [Factor], model: Model?) throws -> (result: Factor?, done: Bool, cont:Bool) {
    model!.newStep()
    for i in 0..<content.endIndex {
        if let action = model!.formerBuffers["action"]?.slotvals["slot\(i + 1)"]?.description {
            print(content[i], action)
            if content[i] != Factor.Str(action) {
                return (nil, false, false) // slots don't match
            }
        } else {
            return (nil, false, false) // There is no action slot
        }
    }
    return (nil, true, false)
}

/**
   Run the model for a specific amount of time
*/
func runRelativeTime(content: [Factor], model: Model?) throws -> (result: Factor?, done: Bool, cont:Bool) {
    guard content.endIndex == 1 else { throw RunTimeError.invalidNumberOfArguments }
    if model!.scenario.nextEventTime == nil {
        var time: Double
        switch content[0] {
        case .IntNumber(let num): time = Double(num)
        case .RealNumber(let num): time = num
        default: throw RunTimeError.nonNumberArgument
        }
        model!.scenario.nextEventTime = model!.time + time
    }
    model!.newStep()
    if model!.time >= model!.scenario.nextEventTime {
        model!.scenario.nextEventTime = nil
        return (nil, true, false)
    } else {
        return (nil, false, false)
    }
}

/**
    Run the model for a specific amount of time OR until it performs
    the specified action. First argument is the amount of time, the
    rest of the arguments are action slots to be compared
*/
func runRelativeTimeOrAction(content: [Factor], model: Model?) throws -> (result: Factor?, done: Bool, cont:Bool) {
    guard content.endIndex > 1 else { throw RunTimeError.invalidNumberOfArguments }
    if model!.scenario.nextEventTime == nil {
        var time: Double
        switch content[0] {
        case .IntNumber(let num): time = Double(num)
        case .RealNumber(let num): time = num
        default: throw RunTimeError.nonNumberArgument
        }
        model!.scenario.nextEventTime = model!.time + time
    }
    model!.newStep()
    var actionFound = true
    for i in 0..<content.endIndex {
        if let action = model!.formerBuffers["action"]?.slotvals["slot\(i + 1)"]?.description {
            print(content[i], action)
            if content[i] != Factor.Str(action) {
                actionFound = false
            }
        } else {
            actionFound = false
        }
    }
    if actionFound || model!.time >= model!.scenario.nextEventTime {
        model!.scenario.nextEventTime = nil
        return (nil, true, false)
    } else {
        return (nil, false, false)
    }
    
}


/**
  Issue a reward
*/
func issueReward(content: [Factor], model: Model?) throws -> (result: Factor?, done: Bool, cont:Bool) {
    var reward = model!.reward
    if content.count > 0 {
        switch (content[0]) {
        case .RealNumber(let num):
            reward = num
        case .IntNumber(let num):
            reward = Double(num)
        default: throw RunTimeError.nonNumberArgument
        }
    }
    model!.operators.updateOperatorSjis(reward)
    return (nil, true, true)
}


