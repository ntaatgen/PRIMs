//
//  Parser.swift
//  actr
//
//  Created by Niels Taatgen on 3/4/15.
//  Copyright (c) 2015 Niels Taatgen. All rights reserved.
//

import Foundation

class Parser  {
    private let m: Model
    let taskNumber: Int
    var scanner: NSScanner
    var startScreenName: String? = nil
    /// Everything after this string on a line will be ignored
    static let commentString = "//"
    init(model: Model, text: String, taskNumber: Int) {
        m = model
        scanner = NSScanner(string: text)
        model.modelText = text
        self.taskNumber = taskNumber
        whitespaceNewLineParentheses.formUnionWithCharacterSet(whitespaceNewLine)
        whiteSpaceNewLineParenthesesEqual.formUnionWithCharacterSet(whitespaceNewLine)
    }
    var defaultActivation: Double? = nil
    private let whitespaceNewLine = NSCharacterSet.whitespaceAndNewlineCharacterSet()
    private let whitespaceNewLineParentheses: NSMutableCharacterSet = NSMutableCharacterSet(charactersInString: "{}()")
    private let whiteSpaceNewLineParenthesesEqual: NSMutableCharacterSet = NSMutableCharacterSet(charactersInString: "{}()=,")
    var globalVariableMapping: [String:Int] = [:]
    
    /** 
    Parse a model file. Takes the String that is entered at the creation of the class instance, and sets
    the necessary variables in the model.
    
    :returns: Whether or not parsing was successful
    */
    func parseModel() -> Bool {
        // First we filter out comments that are marked by the commentString
        var newstring = ""
        scanner.charactersToBeSkipped = nil
        while !scanner.atEnd {
            let stringBeforeComment = scanner.scanUpToString(Parser.commentString)
            if stringBeforeComment != nil {
                newstring += stringBeforeComment!
            }
            scanner.scanUpToString("\n")
            scanner.scanString("\n")
        }
        scanner = NSScanner(string: newstring)
        m.clearTrace()
        while !scanner.atEnd {
            let token = scanner.scanUpToCharactersFromSet(whitespaceNewLineParentheses)
            if token == nil { return false }
//            println("Reading \(token!)")
            switch token! {
            case "define":
                let definedItem = scanner.scanUpToCharactersFromSet(whitespaceNewLineParentheses)
                if definedItem == nil {
                    m.addToTraceField("Unexpected end of file after define")
                    return false
                }
                switch definedItem! {
                case "task": if !parseTask() { return false}
                case "goal": if !parseGoal() { return false }
                case "facts": if !parseFacts() { return false }
                case "screen": if !parseScreen() { return false }
                case "inputs": if !parseInputs() { return false }
                case "goal-action": if !parseGoalAction() { return false }
                case "sji": if !parseSjis() { return false }
                default: m.addToTraceField("Don't know how to define \(definedItem!)")
                    return false
                }
            case "transition": if !parseTransition() { return false}
//            case "start-screen": if !parseStartScreen() { return false}
            default: m.addToTraceField("\(token!) is not a valid top-level statement")
                return false
            }
        }
        if startScreenName == nil {
            m.addToTraceField("No start screen has been defined")
            return false
        }
        if m.scenario.screens[startScreenName!] == nil {
            m.addToTraceField("Start-screen \(startScreenName!) is not defined")
            return false
        }
        m.scenario.startScreen = m.scenario.screens[startScreenName!]!
        return true
    }
    
    func parseTask() -> Bool {
        let taskName = scanner.scanUpToCharactersFromSet(whitespaceNewLineParentheses)
        if taskName == nil {
            m.addToTraceField("Unexpected end of file in goal definition")
            return false
        }
        m.addToTraceField("Defining task \(taskName!)")
        let readBrace = scanner.scanString("{")
        if readBrace == nil {
            m.addToTraceField("'{' Expected after \(taskName!)")
            return false
        }
        var setting: String?
        while !scanner.scanString("}", intoString: nil) {
            setting = scanner.scanUpToCharactersFromSet(whitespaceNewLineParentheses)
            if setting == nil {
                m.addToTraceField("Unexpected end of file in goal definition")
                return false
            }
        switch setting! {
        case "initial-goals:":
            let parenthesis = scanner.scanString("(")
            if parenthesis == nil {
                m.addToTraceField("Missing '(' after initial-goals:")
                return false
            }
            var goal: String?
            let chunk = Chunk(s: "currentGoalChunk", m: m)
            chunk.setSlot("isa", value: "goal")
            var slotCount = 1
            while !scanner.scanString(")", intoString: nil) {
                goal = scanner.scanUpToCharactersFromSet(whitespaceNewLineParentheses)
                if goal == nil {
                    m.addToTraceField("Unexpected end of file in initial-goals:")
                    return false
                }
                if m.dm.chunks[goal!] == nil {
                    let newchunk = Chunk(s: goal!, m: m)
                    newchunk.setSlot("isa", value: "goaltype")
                    newchunk.setSlot("slot1", value: goal!)
                    newchunk.fixedActivation = 1.0 // should change this later
                    newchunk.definedIn = [taskNumber]
                    m.dm.addToDM(newchunk)
                } else {
                    m.dm.chunks[goal!]!.definedIn.append(taskNumber)
                }
                chunk.setSlot("slot\(slotCount++)", value: goal!)
                m.addToTraceField("Task has goal \(goal!)")
                
            }
            m.currentGoals = chunk
        case "goals:":
            let parenthesis = scanner.scanString("(")
            if parenthesis == nil {
                m.addToTraceField("Missing '(' after goals:")
                return false
            }
            var goal: String?
            while !scanner.scanString(")", intoString: nil) {
                goal = scanner.scanUpToCharactersFromSet(whitespaceNewLineParentheses)
                if goal == nil {
                    m.addToTraceField("Unexpected end of file in goals:")
                    return false
                }
                if m.dm.chunks[goal!] == nil {
                    let newchunk = Chunk(s: goal!, m: m)
                    newchunk.setSlot("isa", value: "goaltype")
                    newchunk.setSlot("slot1", value: goal!)
                    newchunk.fixedActivation = 1.0 // should change this later
                    newchunk.definedIn = [taskNumber]
                    m.dm.addToDM(newchunk)
                } else {
                    m.dm.chunks[goal!]!.definedIn.append(taskNumber)
                }
                m.addToTraceField("Task has goal \(goal!)")
                
            }
        case "task-constants:":
            let parenthesis = scanner.scanString("(")
            if parenthesis == nil {
                m.addToTraceField("Missing '(' after initial-constants:")
                return false
            }
            var goal: String?
            let chunk = Chunk(s: "constants", m: m)
            chunk.setSlot("isa", value: "fact")
            var slotCount = 1
            while !scanner.scanString(")", intoString: nil) {
                goal = scanner.scanUpToCharactersFromSet(whitespaceNewLineParentheses)
                if goal == nil {
                    m.addToTraceField("Unexpected end of file in initial-constants:")
                    return false
                }
                globalVariableMapping[goal!] = slotCount
                chunk.setSlot("slot\(slotCount++)", value: goal!)
                m.addToTraceField("Task has constant \(goal!)")
            }
            m.currentGoalConstants = chunk
        case "start-screen:":
            let startScreen = scanner.scanUpToCharactersFromSet(whitespaceNewLine)
            if startScreen == nil {
                m.addToTraceField("Incomplete start-screen declaration")
                return false
            }
            startScreenName = startScreen!
            m.addToTraceField("Setting startscreen to \(startScreen!)")
        case "default-activation:":
            defaultActivation = scanner.scanDouble()
            if defaultActivation == nil {
                m.addToTraceField("Invalid value after default-activation:")
                return false
            }
        default:
            let parValue = scanner.scanUpToCharactersFromSet(whitespaceNewLine)
            if parValue == nil {
                m.addToTraceField("Missing parameter value for \(setting!)")
                return false
            }
            let success = m.setParameter(setting!, value: parValue!)
            if !success {
                m.addToTraceField("Can't set parameter \(setting!) to \(parValue!)")
                return false
            }
            let newSetting = (setting!,parValue!)
            m.parameters.append(newSetting)
            m.addToTraceField("Setting \(setting!) to \(parValue!)")
            }
        }
        m.currentTask = taskName!
        
        return true
    }
    
    func parseGoal() -> Bool {
        let goalName = scanner.scanUpToCharactersFromSet(whitespaceNewLineParentheses)
        if goalName == nil {
            m.addToTraceField("Unexpected end of file in goal definition")
            return false
        }
        m.addToTraceField("Defining goal \(goalName!)")
        if m.dm.chunks[goalName!] == nil {
            m.addToTraceField("Goal \(goalName!) has not been declared at the task level. This may lead to problems.")
            return false
        } else {
            m.dm.chunks[goalName!]!.definedIn.append(taskNumber)
        }

        let readBrace = scanner.scanString("{")
        if readBrace == nil {
            m.addToTraceField("'{' Expected after \(goalName!)")
            return false
        }
        var op: String?
        while !scanner.scanString("}", intoString: nil) {
            op = scanner.scanUpToCharactersFromSet(whitespaceNewLineParentheses)
            if op == nil || op! != "operator" {
                m.addToTraceField("Can only handle operator declarations within a goal definition, but found \(op)")
                return false
            }
            if !parseOperator(goalName!) { return false }
        }
        return true
    }
    
    func parseOperator(goalName: String) -> Bool {
        let operatorName = scanner.scanUpToCharactersFromSet(whitespaceNewLineParentheses)
        if operatorName == nil {
            m.addToTraceField("Unexpected end of file in operator definition")
            return false
        }
        var chunk: Chunk
        if m.dm.chunks[operatorName!] == nil {
            chunk = Chunk(s: operatorName!, m: m)
        } else {
            chunk = m.generateNewChunk(s1: operatorName!)
            m.addToTraceField("Warning: Chunk with name \(operatorName!) already exists, renaming it to \(chunk.name)")
        }
        chunk.fixedActivation = defaultActivation
        m.addToTraceField("Adding operator \(operatorName!)")
        chunk.setSlot("isa", value: "operator")
        var constantSlotCount = 0
        var localVariableMapping: [String:Int] = [:]
        if scanner.scanString("(", intoString: nil) {
            while !scanner.scanString(")", intoString: nil) {
                let parameter = scanner.scanUpToCharactersFromSet(whiteSpaceNewLineParenthesesEqual)
                let equalsign = scanner.scanString("=", intoString: nil)
                if parameter == nil || !equalsign {
                    m.addToTraceField("Illegal parameter declaration in \(operatorName!)")
                    return false
                }
                switch parameter! {
                    case "activation":
                    let activationValue = scanner.scanDouble()
                    if activationValue == nil {
                       m.addToTraceField("Illegal parameter value in \(operatorName!)")
                    return false
                    }
                    chunk.fixedActivation = activationValue!
                    m.addToTraceField("Setting fixed activation to \(activationValue!)")
                default:
                    m.addToTraceField("Unknown parameter \(parameter!)")
                    return false
                }
                scanner.scanString(",", intoString: nil)
            }
        }
        if !scanner.scanString("{", intoString: nil) {
            m.addToTraceField("Missing '{'")
            return false
        }
        var conditions = ""
        var actions = ""
        var scanningActions = false
        while !scanner.scanString("}", intoString: nil) {
            var item = scanner.scanUpToCharactersFromSet(whitespaceNewLineParentheses)
//            println("\(item)")
            if item == nil {
                m.addToTraceField("Unexpected end of file in operator definition")
                return false
            }
            if item!.hasPrefix("\"") {
                scanner.scanUpToString("\"")
                scanner.scanString("\"")
            } else if item! == "==>" {
                scanningActions = true
            } else {
                var prim = ""
                var component = ""
                var complete = false
                while !complete {
//                    println(item! + " " + component)
                    for ch in item! {
                        switch ch {
                        case "A"..."Z","a"..."z","_",".": component += String(ch)
                        default:
                            if component != "" {
                                if bufferMappingA[component] != nil || bufferMappingC[component] != nil || component == "nil" {
                                    prim += component
                                } else if let globalIndex = globalVariableMapping[component] {
                                    prim += "GC\(globalIndex)"
                                } else if let localIndex = localVariableMapping[component] {
                                    prim += "C\(localIndex)"
                                } else {
                                    localVariableMapping[component] = ++constantSlotCount
                                    prim += "C\(constantSlotCount)"
                                    chunk.setSlot("slot\(constantSlotCount)", value: component)
                                }
                                component = ""
                            }
                            prim += String(ch)
                        }
                    }
                    if component != "" {
                        if bufferMappingA[component] != nil || bufferMappingC[component] != nil || component == "nil" {
                            prim += component
                        } else if let globalIndex = globalVariableMapping[component] {
                            prim += "GC\(globalIndex)"
                        } else if let localIndex = localVariableMapping[component] {
                            prim += "C\(localIndex)"
                        } else {
                            localVariableMapping[component] = ++constantSlotCount
                            prim += "C\(constantSlotCount)"
                            chunk.setSlot("slot\(constantSlotCount)", value: component)
                        }
                        component = ""
                    }
                    if parseName(prim).0 == "" { // PRIM is not yet complete
                        item = scanner.scanUpToCharactersFromSet(whitespaceNewLineParentheses)
                        if item == nil {
                            m.addToTraceField("Unexpected end of file in operator definition")
                            return false
                        }
                    } else {
                        complete = true
                    }
                }
                if scanningActions {
                    actions += actions == "" ? prim : ";" + prim
                } else {
                    conditions += conditions == "" ? prim : ";" + prim
                }
            }
        }
        chunk.setSlot("condition", value: conditions)
        chunk.setSlot("action", value: actions)
        chunk.assocs[goalName] = m.dm.defaultOperatorAssoc
        chunk.assocs[chunk.name] = m.dm.defaultOperatorSelfAssoc
        for (_,ch) in m.dm.chunks {
            if ch.type == "operator" && ch.assocs[goalName] != nil {
                chunk.assocs[ch.name] = m.dm.defaultInterOperatorAssoc
                ch.assocs[chunk.name] = m.dm.defaultInterOperatorAssoc
            }
        }
        chunk.definedIn = [taskNumber]
        m.dm.addToDM(chunk)
        m.addToTraceField("Adding operator:\n\(chunk)")
//        println("Adding operator\n\(chunk)")
        
        return true
    }
    
    func parseFacts() -> Bool {
        if !scanner.scanString("{", intoString: nil) {
            m.addToTraceField("Missing '{' in fact definition.")
            return false
        }
        while !scanner.scanString("}", intoString: nil) {
            if !scanner.scanString("(", intoString: nil) {
                m.addToTraceField("Missing '(' in fact definition.")
                return false
            }
            var slotindex = 0
            var chunk: Chunk? = nil
            while !scanner.scanString(")", intoString: nil) {
                let slotValue = scanner.scanUpToCharactersFromSet(whitespaceNewLineParentheses)
                if slotValue == nil {
                    m.addToTraceField("Unexpected end of file in fact defintion")
                    return false
                }
                if slotValue!.hasPrefix(":") {
                    switch slotValue! {
                    case ":activation":
                        let value = scanner.scanDouble()
                        if value == nil || chunk == nil {
                            m.addToTraceField("Invalid parameter value for \(slotValue!)")
                            return false
                        }
                        chunk!.fixedActivation = value!
                    default:
                        m.addToTraceField("Unknown parameter \(slotValue!)")
                        return false
                    }
                } else {
                    
                    if slotindex == 0 {
                        chunk =  Chunk(s: slotValue!, m: m)
                        chunk!.setSlot("isa", value: "fact")
                        chunk!.fixedActivation = defaultActivation
                        slotindex++
                    } else {
                        chunk!.setSlot("slot\(slotindex++)", value: slotValue!)
                    }
                }
                
            }
            m.addToTraceField("Reading fact \(chunk!.name)")
            chunk!.definedIn = [taskNumber]
            m.dm.addToDM(chunk!)
        }
        return true
    }
    
    func parseGoalAction() -> Bool {
        if !scanner.scanString("{", intoString: nil) {
            m.addToTraceField("Missing '{' in goal-action definition.")
            return false
        }
        m.scenario.goalAction = []
        if !scanner.scanString("(", intoString: nil) {
            m.addToTraceField("Missing '(' in goal-action definition")
            return false
        }
        while !scanner.scanString(")", intoString: nil) {
            let name = scanner.scanUpToCharactersFromSet(whitespaceNewLineParentheses)
            if name == nil {
                m.addToTraceField("Unexpected end of file in goal-action definition")
                return false
            }
            m.scenario.goalAction.append(name!)
        }
        if !scanner.scanString("}", intoString: nil) {
            m.addToTraceField("Missing '}' in goal-action definition.")
            return false
        }
        m.addToTraceField("Defining goal-action \(m.scenario.goalAction)")
        return true
    }
    
    func parseScreen() -> Bool {
        let name = scanner.scanUpToCharactersFromSet(whitespaceNewLineParentheses)
        if name == nil {
            m.addToTraceField("Missing name in screen definition")
            return false
        }
        if !scanner.scanString("{", intoString: nil) {
            m.addToTraceField("Missing '{' in screen \(name!) definition.")
            return false
        }
        let screen = PRScreen(name: name!)
        let topObject = PRObject(name: "card", attributes: ["card"], superObject: nil)
        screen.object = topObject
        while !scanner.scanString("}", intoString: nil) {
            if !scanner.scanString("(", intoString: nil) {
                m.addToTraceField("Missing '(' in object definition below \(name!)")
                return false
            }
            if !parseObject(topObject) { return false }
        }
        m.scenario.screens[screen.name] = screen
        m.addToTraceField("Adding screen \(screen.name)")
        return true
    }
    
    func parseObject(superObject: PRObject) -> Bool {
        let name = scanner.scanUpToCharactersFromSet(whitespaceNewLineParentheses)
        if name == nil {
            m.addToTraceField("Missing name in object definition")
            return false
        }
        var attributes: [String] = [name!]
        while let attribute = scanner.scanUpToCharactersFromSet(whitespaceNewLineParentheses) {
            attributes.append(attribute)
        }
        let object = PRObject(name: m.generateName(s1: name!), attributes: attributes, superObject: superObject)
        m.addToTraceField("Adding object \(object.name) with attributes \(object.attributes)")
        while scanner.scanString("(", intoString: nil) {
            parseObject(object)
        }
        if !scanner.scanString(")", intoString: nil) {
            m.addToTraceField("Missing ')' in object definition \(name!)")
            return false
        }
        return true
    }
    
    func parseTransition() -> Bool {
        let parenthesis1 = scanner.scanString("(", intoString: nil)
        let screen1 = scanner.scanUpToCharactersFromSet(whiteSpaceNewLineParenthesesEqual)
        let comma = scanner.scanString(",", intoString: nil)
        let screen2 = scanner.scanUpToCharactersFromSet(whiteSpaceNewLineParenthesesEqual)
        let parenthesis2 = scanner.scanString(")", intoString: nil)
        let equalSign = scanner.scanString("=", intoString: nil)
        let transType = scanner.scanUpToCharactersFromSet(whitespaceNewLineParentheses)
        let parenthesis3 = scanner.scanString("(", intoString: nil)
        if !parenthesis1 || !parenthesis2 || !comma || !parenthesis3 || !equalSign || screen1 == nil || screen2 == nil || transType == nil {
            m.addToTraceField("Illegal transition syntax")
            return false
        }
        let sourceScreen = m.scenario.screens[screen1!]
        let destinationScreen = m.scenario.screens[screen2!]
        if sourceScreen == nil || destinationScreen == nil {
            m.addToTraceField("Either \(screen1!) or \(screen2!) is undeclared")
            return false
        }
        switch transType! {
            case "absolute-time":
            let time = scanner.scanDouble()
            if time == nil {
                m.addToTraceField("Missing Double after absolute-time")
                return false
            }
            sourceScreen!.timeTransition = time!
            sourceScreen!.timeTarget = destinationScreen!
            sourceScreen!.timeAbsolute = true
            case "relative-time":
                let time = scanner.scanDouble()
                if time == nil {
                    m.addToTraceField("Missing Double after relative-time")
                    return false
                }
                sourceScreen!.timeTransition = time!
                sourceScreen!.timeTarget = destinationScreen!
                sourceScreen!.timeAbsolute = false
            case "action":
            let action = scanner.scanUpToCharactersFromSet(whiteSpaceNewLineParenthesesEqual)
            if action == nil {
                m.addToTraceField("Missing action in transition")
                return false
            }
            sourceScreen!.transitions[action!] = destinationScreen!
        default:
            m.addToTraceField("Unknown transition type \(transType!)")
            return false
        }
        scanner.scanString(")", intoString: nil)
        m.addToTraceField("Defining transition between \(screen1!) and \(screen2!)")
        return true
    }

    func parseInputs() -> Bool {
        if !scanner.scanString("{", intoString: nil) {
            m.addToTraceField("Missing '{' in inputs definition.")
            return false
        }
        var inputCount = 0
        while !scanner.scanString("}", intoString: nil) {
            if !scanner.scanString("(", intoString: nil) {
                m.addToTraceField("Missing '(' in input definition.")
                return false
            }
            var slotindex = 0
            var mapping: [String:String] = [:]
            while !scanner.scanString(")", intoString: nil) {
                let value = scanner.scanUpToCharactersFromSet(whitespaceNewLineParentheses)
                if value == nil {
                    m.addToTraceField("Unexpected end of file in input defintion")
                    return false
                }
                mapping["?\(slotindex++)"] = value!
            }
            m.scenario.inputs["task\(inputCount++)"] = mapping
            m.addToTraceField("Reading input \(mapping)")
        }
        return true

    }

    func parseSjis() -> Bool {
        if !scanner.scanString("{", intoString: nil) {
            m.addToTraceField("Missing '{' in Sji definition.")
            return false
        }
        while !scanner.scanString("}", intoString: nil) {
            if !scanner.scanString("(", intoString: nil) {
                m.addToTraceField("Missing '(' in Sji definition.")
                return false
            }
            let jChunkName = scanner.scanUpToCharactersFromSet(whiteSpaceNewLineParenthesesEqual)
            let iChunkName = scanner.scanUpToCharactersFromSet(whiteSpaceNewLineParenthesesEqual)
            let assocValue = scanner.scanDouble()
            if jChunkName == nil || iChunkName == nil || assocValue == nil {
                m.addToTraceField("Incomplete Sji definition")
                return false
            }
            if m.dm.chunks[jChunkName!] == nil {
                m.addToTraceField("Chunk \(jChunkName!) is not defined.")
                return false
            }
            if m.dm.chunks[iChunkName!] == nil {
                m.addToTraceField("Chunk \(iChunkName!) is not defined.")
                return false
            }
            m.dm.chunks[iChunkName!]!.assocs[jChunkName!] = assocValue
            if !scanner.scanString(")", intoString: nil) {
                m.addToTraceField("Missing ')' in Sji definition.")
            }
            m.addToTraceField("Adding association between \(jChunkName!) and \(iChunkName!)")
        }
        return true
    }

}