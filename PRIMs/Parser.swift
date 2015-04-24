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
    
    
    init(model: Model, text: String) {
        m = model
        t = Tokenizer(s: text)
        model.modelText = text
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
                    if chunk != nil {  m.dm.addToDM(chunk!)
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
            case "set-goal":
                t.nextToken()
                m.currentTask = t.token!
                println("The goaltype is \(t.token!)")
                let chunk = Chunk(s: t.token!, m: m)
                chunk.setSlot("isa", value: "goal")
                chunk.setSlot("type", value: t.token! + "-goal")
                m.dm.addToDM(chunk)
                t.nextToken()
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
    /*
    private func parseProduction() -> Production? {
    let name = t.token!
    t.nextToken()
    let p = Production(name: name, model: m)
    while (t.token != nil && t.token! != "==>") {
    let bc = parseBufferCondition()
    if bc != nil { p.addCondition(bc!) }
    }
    if t.token != "==>" { println("Parsing error in \(name)") }
    t.nextToken()
    while (t.token != nil && t.token != ")") {
    let ac = parseBufferAction()
    if ac !=  nil { p.addAction(ac!) }
    }
    t.nextToken()
    return p
    }
    
    private func parseBufferCondition() -> BufferCondition? {
    let prefix = String(t.token![t.token!.startIndex])
    let token = t.token!
    let start = advance(token.startIndex,1)
    let end = advance(token.endIndex,-1)
    let bufferName = token[Range(start: start, end: end)]
    let buffer = (prefix == "?" ? "?" : "") + bufferName
    t.nextToken()
    let bc = BufferCondition(prefix: prefix, buffer: buffer, model: m)
    while (t.token != nil  && !t.token!.hasPrefix("?") && !(t.token!.hasPrefix("=") && t.token!.hasSuffix(">"))) {
    let sc = parseSlotCondition()
    if sc != nil { bc.addCondition(sc!) }
    }
    return bc
    }
    
    
    private func parseSlotCondition() -> SlotCondition? {
    var op: String? = nil
    if (t.token == "-" || t.token == "<" || t.token == ">" || t.token == "<=" || t.token == ">=") {
    op = t.token
    t.nextToken()
    }
    let slot = t.token
    t.nextToken()
    let value = t.token
    t.nextToken()
    if slot != nil && value != nil {
    return SlotCondition(op: op, slot: slot!, value: m.stringToValue(value!), model: m)
    }
    else { return nil }
    }
    
    
    private func parseBufferAction() -> BufferAction? {
    let prefix = String(t.token![t.token!.startIndex])
    let token = t.token!
    let start = advance(token.startIndex,1)
    let end = advance(token.endIndex,-1)
    let buffer = token[Range(start: start, end: end)]
    t.nextToken()
    let ba = BufferAction(prefix: prefix, buffer: buffer, model: m)
    if prefix == "-" { return ba }
    /// Possible direct action
    while (t.token != nil && !t.token!.hasPrefix("+") && t.token! != ")" && !(t.token!.hasPrefix("-") && t.token!.hasSuffix(">")) && !(t.token!.hasPrefix("=") && t.token!.hasSuffix(">"))) {
    let ac = parseSlotAction()
    if ac != nil { ba.addAction(ac!) }
    }
    return ba
    }
    
    
    
    private func parseSlotAction() -> SlotAction? {
    var op: String? = nil
    if (t.token == "-" || t.token == "<" || t.token == ">" || t.token == "<=" || t.token == ">=") {
    op = t.token
    t.nextToken()
    }
    let slot = t.token
    t.nextToken()
    let value = t.token
    t.nextToken()
    if slot != nil && value != nil {
    return SlotAction(slot: slot!, value: m.stringToValue(value!))
    }
    else { return nil }
    
    }
    */
}