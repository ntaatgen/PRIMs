//
//  Parser.swift
//  actr
//
//  Created by Niels Taatgen on 3/4/15.
//  Copyright (c) 2015 Niels Taatgen. All rights reserved.
//

import Foundation

class Parser  {
    private let t: Tokenizer
    private let m: Model
    let taskNumber: Int
    
    init(model: Model, text: String, taskNumber: Int) {
        m = model
        t = Tokenizer(s: text)
        model.modelText = text
        self.taskNumber = taskNumber
    }
    
    func parseModel() {
        while (t.token != nil && t.token! != ")") {
            if t.token! != "(" {
                println("( expected but found \(t.token!)")
                return
            }
            t.nextToken()
            switch t.token! {
            case "add-dm":
                println("Add-dm")
                t.nextToken()
                var chunk: Chunk?
                do {
                    chunk = parseChunk(m.dm)
                    println("Parsed \(chunk)")
                    if chunk != nil {
                        chunk!.definedIn = taskNumber
                        m.dm.addToDM(chunk!)
                    }
                } while (chunk != nil && t.token != ")")
                if t.token != ")" {
                    println(") expected")
                    return
                }
                t.nextToken()
                //            case "p":
                //                    t.nextToken()
                //                    let prod = parseProduction()
                //                    if prod != nil { m.procedural.addProduction(prod!) }
            case "set-task":
                t.nextToken()
                m.currentTask = t.token!
                println("The task is \(t.token!)")
                t.nextToken()
                t.nextToken()
            case "set-goal":
                t.nextToken()
                var slotcount = 1
                let chunk = Chunk(s: "currentGoalChunk", m: m)
                chunk.setSlot("isa", value: "goal")
                chunk.setSlot("slot1", value: "start")
                while t.token! != ")" {
                    if m.dm.chunks[t.token!] == nil {
                        let newchunk = Chunk(s: t.token!, m: m)
                        newchunk.setSlot("isa", value: "goaltype")
                        newchunk.setSlot("slot1", value: t.token!)
                        newchunk.fixedActivation = 1.0 // should change this later
                        m.dm.addToDM(newchunk)
                    }
                    chunk.setSlot("slot\(slotcount++)", value: t.token!)
                    t.nextToken()
                }
                m.currentGoals = chunk
                println("The goalchunk is \(chunk)")
                t.nextToken()
            case "set-goal-constants":
                t.nextToken()
                var slotcount = 1
                let chunk = Chunk(s: "constants", m: m)
                chunk.setSlot("isa", value: "fact")
                while t.token! != ")" {
                    chunk.setSlot("slot\(slotcount++)", value: t.token!)
                    t.nextToken()
                }
                m.currentGoalConstants = chunk
                println("The goal constants are is \(chunk)")
                t.nextToken()
            case "specify-inputs":
                t.nextToken()
                var chunk: Chunk?
                do {
                    chunk = parseInput()
                    println("Parsed \(chunk)")
                    if chunk != nil {
                        m.inputs.append(chunk!)
                    }
                } while (chunk != nil && t.token != ")")
                if t.token != ")" {
                    println(") expected")
                    return
                }
               println("Inputs:\n\(m.inputs)")
                
            case "goal-focus":
                t.nextToken()
                if let chunk = m.dm.chunks[t.token!] {
                    let goalChunk = chunk.copy()
                    m.buffers["goal"] = goalChunk
                }
                t.nextToken()
                t.nextToken()
            case "set-all-baselevels":
                t.nextToken()
                if let timeDiff = NSNumberFormatter().numberFromString(t.token!)?.doubleValue {
                    t.nextToken()
                    if let number = NSNumberFormatter().numberFromString(t.token!)?.intValue {
                        for (_,chunk) in m.dm.chunks {
                            chunk.setBaseLevel(timeDiff, references: Int(number))
                        }
                    }
                }
                t.nextToken()
                if t.token != ")" {
                    println(") expected")
                    return
                }
                t.nextToken()
            case "sgp":
                t.nextToken()
                while t.token! != ")" {
                    let parameter = t.token!
                    t.nextToken()
                    let value = t.token!
                    t.nextToken()
                    if !m.setParameter(parameter,value: value) {
                        println("Problem parseing parameter/value pair \(parameter) and \(value)")
                        return
                    }
                    else {
                        m.parameters.append((parameter,value))
                    }
                }
                t.nextToken()
            case "screen":
                t.nextToken()
                let screen = parseScreen()
                m.scenario.screens[screen.name] = screen
                t.nextToken()
            case "start-screen":
                t.nextToken()
                m.scenario.startScreen = m.scenario.screens[t.token!]!
                println("Setting startScreen to \(m.scenario.startScreen.name)")
                t.nextToken()
                t.nextToken()
            case "transition":
                t.nextToken()
                let sourceScreen = m.scenario.screens[t.token!]
                t.nextToken()
                let destinationScreen = m.scenario.screens[t.token!]
                if sourceScreen == nil || destinationScreen == nil {
                    println("Illegal transition")
                    return
                }
                println("Setting transition between \(sourceScreen!.name) and \(destinationScreen!.name)")
                t.nextToken()
                switch t.token! {
                case "relative-time":
                    t.nextToken()
                    let relTime = NSNumberFormatter().numberFromString(t.token!)?.doubleValue
                    if relTime != nil {
                        sourceScreen!.timeTransition = relTime!
                        sourceScreen!.timeTarget = destinationScreen!
                        sourceScreen!.timeAbsolute = false
                    } else {
                        println("Illegal time in transition")
                        return
                    }
                case "absolute-time":
                    t.nextToken()
                    let absTime = NSNumberFormatter().numberFromString(t.token!)?.doubleValue
                    if absTime != nil {
                        sourceScreen!.timeTransition = absTime!
                        sourceScreen!.timeTarget = destinationScreen!
                        sourceScreen!.timeAbsolute = true
                    } else {
                        println("Illegal time in transition")
                        return
                    }
                case "action":
                    t.nextToken()
                    sourceScreen!.transitions[t.token!] = destinationScreen
                default:
                    println("Unknown transition type \(t.token!)")
                    return
                }
                t.nextToken()
                t.nextToken()
            default: println("Cannot yet handle \(t.token!)")
                return
            }
        }
    }
    
    private func parseChunk(dm: Declarative) -> Chunk? {
        if t.token != "(" {
            println("( expected")
            return nil
        }
        t.nextToken()
        let chunkName = t.token!
        t.nextToken()
        let chunk = Chunk(s: chunkName, m: m)
        while (t.token != nil && t.token! != ")") {
            let slot = t.token
            t.nextToken()
            let valuestring = t.token
            t.nextToken()
            if (slot != nil && valuestring != nil) {
                if let number = NSNumberFormatter().numberFromString(valuestring!)?.doubleValue   {
                    if slot != ":activation" {
                        chunk.setSlot(slot!, value: number)
                    } else {
                        chunk.fixedActivation = number
                    }
                } else if slot! == ":assoc" {
                    let value = dm.chunks[valuestring!]
                    if value != nil {
                        chunk.assocs[valuestring!] = dm.defaultOperatorAssoc
//                        println("Setting assoc between \(valuestring) and \(chunkName)")
                    }
                    else {
                        println("Invalid :assoc definition in \(chunkName)")
                    }
                }
                else {
                    chunk.setSlot(slot!,value: valuestring!)
                }
            }
            else {
                println("Wrong chunk syntax")
                return nil
            }
        }
        if (t.token == nil || t.token! != ")") {
            return nil }
        t.nextToken()
        return chunk
    }
    
    private func parseInput() -> Chunk? {
        if t.token != "(" {
            println("( expected")
            return nil
        }
        t.nextToken()
        let chunkName = t.token!
        t.nextToken()
        let chunk = Chunk(s: chunkName, m: m)
        var i = 1
        while (t.token != nil && t.token! != ")") {
            let slot = "slot" + String(i++)
            let valuestring = t.token
            t.nextToken()
            if (valuestring != nil) {
                if let number = NSNumberFormatter().numberFromString(valuestring!)?.doubleValue   {
                    if slot != ":activation" {
                        chunk.setSlot(slot, value: number)
                    } else {
                        chunk.fixedActivation = number
                    }
                } else {
                    chunk.setSlot(slot,value: valuestring!)
                } }
            else {
                println("Wrong chunk syntax")
                return nil
            }
        }
        if (t.token == nil || t.token! != ")") {
            return nil }
        t.nextToken()
        return chunk
    }
    
    private func parseScreen() -> PRScreen {
        let name = t.token!
        println("Parsing Screen \(name)")
        let screen = PRScreen(name: name)
        t.nextToken() // Should be "("
        t.nextToken() // Should be the identifier of single object in the Screen
        let card = parseObject(nil)
        screen.object = card
        return screen
    }
    
    private func parseObject(superObject: PRObject?) -> PRObject {
        let name = t.token!
        var attributes: [String] = []
        t.nextToken()
        while (t.token != "(" && t.token != ")") {
            attributes.append(t.token!)
            t.nextToken()
        }
        println("Parsing object \(name) with attributes \(attributes) and parent \(superObject?.name)")
        let obj = PRObject(name: name, attributes: attributes, superObject: superObject)
        while (t.token == "(") {
            t.nextToken()
            let subObject = parseObject(obj)
        }
        t.nextToken() // closing ")"
        return obj
    }
    
       

}