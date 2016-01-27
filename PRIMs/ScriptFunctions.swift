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
    "nested-screen": setScreenArray,
    "random": randIntNumber,
    "time": modelTime,
    "run-step": runStep,
    "run-until-action": runUntilAction,
    "run-relative-time": runRelativeTimeOrAction,
    "run-absolute-time": runAbsoluteTimeOrAction,
    "run-until-relative-time-or-action": runRelativeTimeOrAction,
    "run-absolute-time-or-action": runAbsoluteTimeOrAction,
    "print": printArg,
    "trial-end": trialEnd,
    "trial-start": trialStart,
    "issue-reward": issueReward,
    "shuffle": shuffle,
    "length": length,
    "sleep": sleepPrims,
    "set-data-file-field": setDataFileField,
    "last-action": lastAction
    ]



/// Things that can be set
// model.scenario.nextEventTime: time at which the script continues
// model.scenario.currentScreen: screen we are working on

/**
    Helper function for setScreenArray
*/
func createPRObject(f: ScriptArray, sup: PRObject?, model: Model) throws -> PRObject {
    guard f.elements.count > 0 else { throw RunTimeError.errorInFunction("Invalid Screen definition") }
    let name = f.elements[0].firstTerm.factor.description
    var i = 1
    var attributes: [String] = [name]
    var done = false
    while i < f.elements.count && !done {
        switch f.elements[i].firstTerm.factor {
        case .Str(let s):
            attributes.append(s)
        case .IntNumber(let num):
            attributes.append(String(num))
        case .RealNumber(let num):
            attributes.append(String(num))
        case .Arr:
            done = true
            i--
        default:
            throw RunTimeError.errorInFunction("Invalid Screen definition")
        }
        i++
    }
    let obj = PRObject(name: model.generateName(name), attributes: attributes, superObject: sup)
    while (i < f.elements.count) {
        switch f.elements[i].firstTerm.factor {
        case .Arr(let arr):
            let _ = try createPRObject(arr, sup: obj, model: model)
        default:
            throw RunTimeError.errorInFunction("Invalid Screen definition")
        }
        i++
    }
    return obj
}

/**
 Set the screen to a particular context.
 Pass a set of (possibly nested) Arrays (e.g. screen(["acquarium", "one", ["fish", "red"], ["fish", "green"]])).
 */
func setScreenArray(content: [Factor], model: Model?) throws -> (result: Factor?, done: Bool, cont: Bool) {
    let screen = PRScreen(name: "run-time")
    let rootObject = PRObject(name: "card", attributes: ["card"], superObject: nil)
    screen.object = rootObject
    for obj in content {
        switch obj {
        case .Arr(let arr):
            let obj = try createPRObject(arr, sup: rootObject, model: model!)
            rootObject.subObjects.append(obj)
        default:
            throw RunTimeError.errorInFunction("Wrong argument in screen-array")
        }
    }
    model!.scenario.currentScreen = screen
    screen.start()
    model!.buffers["input"] = model!.scenario.current(model!)
    return (nil, true, true)
}


/**
    Set the screen to a particular context. Can be called in two different ways.
    Just pass the contents of the screen as arguments (e.g. screen("one","two").
*/
func setScreen(content: [Factor], model: Model?) throws -> (result: Factor?, done: Bool, cont: Bool) {
    let screen = PRScreen(name: "run-time")
    let rootObject = PRObject(name: "card", attributes: ["card"], superObject: nil)
    screen.object = rootObject
    var attributes: [String] = []
    for obj in content {
        switch obj {
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
   Starts a trial: adds a line to the data and sets the startTime to the current model time.
   Also causes model to pause when stepping
*/
 func trialStart(content: [Factor], model: Model?) throws -> (result: Factor?, done: Bool, cont:Bool) {
    model!.startTime = model!.time
    return (nil, true, false)
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
    model!.commitToTrace(false)
    model!.initializeNextTrial()
    return(nil, true, false)
}

/**
  Run the model a single step
*/
func runStep(content: [Factor], model: Model?) throws -> (result: Factor?, done: Bool, cont:Bool) {
    model!.newStep()
    print("Running a step")
    return (nil, true, false)
}

/**
  Run the model until it takes the action specified
*/
func runUntilAction(var content: [Factor], model: Model?) throws -> (result: Factor?, done: Bool, cont:Bool) {
    print("Running until action \(content)")
    content.insert(Factor.RealNumber(-1.0), atIndex: 0)
    return try runRelativeTimeOrAction(content, model: model)
}


/**
    Run the model for a specific amount of time OR until it performs
    the specified action. First argument is the amount of time, the
    rest of the arguments are action slots to be compared
*/
func runRelativeTimeOrAction(content: [Factor], model: Model?) throws -> (result: Factor?, done: Bool, cont:Bool) {
    guard content.endIndex >= 1 else { throw RunTimeError.invalidNumberOfArguments }
    if model!.scenario.nextEventTime == nil {
        var time: Double
        switch content[0] {
        case .IntNumber(let num): time = Double(num)
        case .RealNumber(let num): time = num
        default: throw RunTimeError.nonNumberArgument
        }
        if time >= 0 {
            model!.scenario.nextEventTime = model!.time + time
        }
    }
    model!.newStep()
    var actionFound: Bool
    if content.endIndex == 1 {
        actionFound = false
    } else {
        actionFound = true
        for i in 1..<content.endIndex {
            if let action = model!.formerBuffers["action"]?.slotvals["slot\(i)"]?.description {
                print(content[i], action)
                if content[i] != Factor.Str(action) {
                    actionFound = false
                } else {
                    print("Match")
                }
            } else {
                actionFound = false
            }
        }
    }
    if actionFound || (model!.scenario.nextEventTime != nil && model!.time >= model!.scenario.nextEventTime) {
        model!.scenario.nextEventTime = nil
        return (nil, true, false)
    } else {
        return (nil, false, false)
    }
    
}

/**
 Run the model until a certain moment in time OR until it performs
 the specified action. First argument is the time, the
 rest of the arguments are action slots to be compared
 */
func runAbsoluteTimeOrAction(content: [Factor], model: Model?) throws -> (result: Factor?, done: Bool, cont:Bool) {
    guard content.endIndex >= 1 else { throw RunTimeError.invalidNumberOfArguments }
    if model!.scenario.nextEventTime == nil {
        var time: Double
        switch content[0] {
        case .IntNumber(let num): time = Double(num)
        case .RealNumber(let num): time = num
        default: throw RunTimeError.nonNumberArgument
        }
        model!.scenario.nextEventTime = time
    }
    return try runRelativeTimeOrAction(content, model: model)
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

/**
  Move the model clock forward by the number of seconds in the argument
*/
func sleepPrims(content: [Factor], model: Model?) throws -> (result: Factor?, done: Bool, cont:Bool) {
    guard content.endIndex == 1 else { throw RunTimeError.invalidNumberOfArguments }
    switch content[0] {
    case .IntNumber(let num):
        model!.time += Double(num)
    case .RealNumber(let num):
        model!.time += num
    default: throw RunTimeError.nonNumberArgument
    }
    return (nil, true, true)
}

/**
  Return the length of an array
*/
func length(content: [Factor], model: Model?) throws -> (result: Factor?, done: Bool, cont:Bool) {
    guard content.endIndex == 1 else { throw RunTimeError.invalidNumberOfArguments }
    switch content[0] {
    case .Arr(let a): return (Factor.IntNumber(a.elements.count), true, true)
    case .Str(let s): return (Factor.IntNumber(s.characters.count), true, true)
    default: throw RunTimeError.errorInFunction("Trying to get the length of a non-array or -string")
    }
}

/** 
Set one of the input variables to a value, so that it will show up in the
output file
*/
func setDataFileField(content: [Factor], model: Model?) throws -> (result: Factor?, done: Bool, cont:Bool) {
    guard content.endIndex == 2 else { throw RunTimeError.invalidNumberOfArguments }
    guard content[0].type() == "integer" else { throw RunTimeError.nonNumberArgument }
    model!.scenario.currentInput["?\(content[0].intValue()!)"] = content[1].description
    return (nil, true, true)
}

/**
Return array with the last action
*/
func lastAction(content: [Factor], model: Model?) throws -> (result: Factor?, done: Bool, cont:Bool) {
    var result: [Expression] = []
    if let action = model!.formerBuffers["action"] {
        var i = 1
        while (action.slotvals["slot\(i)"] != nil) {
            result.append(Expression(preop: "", firstTerm: Term(factor: Factor.Str(action.slotvals["slot\(i)"]!.description), op: "", term: nil), op: "", secondTerm: nil))
            i++
        }
    }
    return(Factor.Arr(ScriptArray(elements: result)), true, true)
}
