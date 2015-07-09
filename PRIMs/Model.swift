//
//  Model.swift
//  actr
//
//  Created by Niels Taatgen on 3/1/15.
//  Copyright (c) 2015 Niels Taatgen. All rights reserved.
//

import Foundation

struct DataLine {
    var eventType: String
    var eventParameter1: String
    var eventParameter2: String = "void"
    var eventParameter3: String = "void"
    var inputParameters: [String] = ["void","void","void","void","void"]
    var time: Double
}

class Model {
    var time: Double = 0
    lazy var dm: Declarative = { () -> Declarative in return Declarative(model: self) }()
    lazy var procedural: Procedural = { () -> Procedural in return Procedural(model: self) }()
    lazy var imaginal: Imaginal = { () -> Imaginal in return Imaginal(model: self) }()
    lazy var action: Action = { () -> Action in return Action(model: self) }()
    var buffers: [String:Chunk] = [:]
    var chunkIdCounter = 0
    var running = false
    var startTime: Double = 0.0
    var trace: String {
        didSet {
            NSNotificationCenter.defaultCenter().postNotificationName("TraceChanged", object: nil)
        }
    }
    var waitingForAction: Bool = false {
        didSet {
            if waitingForAction == true {
//                println("Posted Action notification")
                NSNotificationCenter.defaultCenter().postNotificationName("Action", object: nil)
            }
        }
    }
    var modelText: String = ""
    var currentTask: String? = nil /// What is the name of the current task
    var currentGoals: Chunk? = nil /// Chunk that has the goals to implement the task
    var currentGoalConstants: Chunk? = nil
    var tracing: Bool = true
    var parameters: [(String,String)] = []
    var scenario = PRScenario()
    /// Maximum time to run the model
    var timeThreshold = 200.0
    var outputData: [DataLine] = []
    var formerBuffers: [String:Chunk] = [:]
    static let rewardDefault = 0.0
    /// Reward used for operator-goal association learning. Also determines maximum run time. Switched off when set to 0.0 (default)
    var reward: Double = rewardDefault
    var stepping = false
    
//    struct Results {
        var modelResults: [[(Double,Double)]] = []
        var resultTaskNumber: [Int] = []
        var currentRow = -1
        var maxX = 0.0
        var maxY = 0.0
        var currentTrial = 1.0
        func resultAdd(y:Double) {
            let x = currentTrial
            currentTrial += 1.0
            if currentRow < modelResults.count {
                modelResults[currentRow].append((x,y))
                maxX = max(maxX, x)
            } else {
                var newItem = [(1.0,y)]
                modelResults.insert(newItem, atIndex: currentRow)
                currentTrial = 2.0
            }
            maxY = max(maxY, y)
        }
        func newResult() {
            if currentRow < modelResults.count {
                currentRow = currentRow + 1
                resultTaskNumber.append(currentTaskIndex!)
            } else {
                resultTaskNumber[currentRow] = currentTaskIndex!
            }
        }
    func clearResults() {
        modelResults = []
        resultTaskNumber = []
        currentRow = -1
        maxX = 0.0
        maxY = 0.0
        currentTrial = 1.0
    }
        
    init() {
        trace = ""
    }
    
    var traceBuffer: [String] = []
    
    
    func addToTrace(s: String) {
        if tracing {
        let timeString = String(format:"%.2f", time)
//        println("\(timeString)  " + s)
        traceBuffer.append("\(timeString)  " + s)
//        trace += "\(timeString)  " + s + "\n"
        }
    }
    
    func commitToTrace(indented: Bool) {
        for s in traceBuffer {
            if indented {
                trace += "      "
            }
            trace += s + "\n"
        }
        traceBuffer = []
    }
    
    func addToTraceField(s: String) {
        trace += s + "\n"
    }
    
    func clearTrace() {
        trace = ""
    }
    
//    func buffersToText() -> String {
//        var s: String = ""
//        let bufferList = ["goal","operator","imaginal","retrievalR","retrievalH","input","action","constants"]
//        for buffer in bufferList {
//            var bufferChunk = buffers[buffer]
//            if bufferChunk == nil { bufferChunk = formerBuffers[buffer] }
//            if bufferChunk != nil {
//                s += "=" + buffer + ">" + "\n"
//                s += "  " + bufferChunk!.name
//                for slot in bufferChunk!.printOrder {
//                    if let descr = bufferChunk!.slotvals[slot]?.description {
//                        s += "  " + slot + " " + descr + "\n"
//                    }
//                }
//                s += "\n"
//            }
//        }
//        return s
//    }
    
    /*
    Code to represent all the tasks
    */
    
    var tasks: [Task] = []
    var currentTaskIndex: Int? = nil

    func findTask(taskName: String) -> Int? {
        for i in 0..<tasks.count {
            if tasks[i].name == taskName {
                return i
            }
        }
        return nil
    }
    
    
    func parseCode(modelCode: String, taskNumber: Int) -> Bool {
        let parser = Parser(model: self, text: modelCode, taskNumber: taskNumber)
        let result = parser.parseModel()
        if result {
            modelText = modelCode
            newResult()
        }
        return result
    }
    

    func initializeNewTrial() {
        startTime = time
        buffers = [:]
        procedural.reset()
        buffers["goal"] = currentGoals?.copy()
        buffers["constants"] = currentGoalConstants?.copy()
        formerBuffers = [:]
        formerBuffers["goal"] = buffers["goal"]?.copyLiteral()
        formerBuffers["constants"] = buffers["constants"]?.copyLiteral()
        action.initTask()
        formerBuffers["input"] = buffers["input"]?.copyLiteral()
        running = true
        clearTrace()
        outputData = []
        previousOperators = []
    }
    
    func setParameter(parameter: String, value: String) -> Bool {
        let numVal = string2Double(value)
        let boolVal = (value != "nil")
        switch parameter {
        case "imaginal-autoclear:":
            imaginal.autoClear = boolVal
        case "ol:":
            dm.optimizedLearning = boolVal
        case "goal-operator-learning:":
            dm.goalOperatorLearning = boolVal
        default:
            if (numVal == nil) {return false}
            switch parameter {
            case "imaginal-delay:":
                imaginal.imaginalLatency = numVal!
            case "egs:":
                procedural.utilityNoise = numVal!
            case "alpha:":
                procedural.alpha = numVal!
            case "nu:":
                procedural.defaultU = numVal!
            case "primU:":
                procedural.primU = numVal!
            case "utility-retrieve-operator:":
                procedural.utilityRetrieveOperator = numVal!
            case "dat:":
                procedural.productionActionLatency = numVal!
            case "bll:":
                dm.baseLevelDecay = numVal!
            case "mas:":
                dm.maximumAssociativeStrength = numVal!
            case "rt:":
                dm.retrievalThreshold = numVal!
            case "lf:":
                dm.latencyFactor = numVal!
            case "mp:":
                dm.misMatchPenalty = numVal!
            case "ans:":
                dm.activationNoise = numVal!
            case "ga:":
                dm.goalActivation = numVal!
            case "input-activation:":
                dm.inputActivation = numVal!
            case "default-operator-assoc:":
                dm.defaultOperatorAssoc = numVal!
            case "default-operator-self-assoc:":
                dm.defaultOperatorSelfAssoc = numVal!
            case "production-prim-latency:":
                procedural.productionAndPrimLatency = numVal!
            case "say-latency:":
                action.sayLatency = numVal!
            case "subvocalize-latency:":
                action.subvocalizeLatency = numVal!
            case "read-latency:":
                action.readLatency = numVal!
            case "perception-action-latency:":
                action.defaultPerceptualActionLatency = numVal!
            case "beta:":
                dm.beta = numVal!
            case "reward:":
                    self.reward = numVal!
            case "explore-exploit:":
                dm.explorationExploitationFactor = numVal!
            default: return false
            }
        }
        //        println("Parameter \(parameter) has value \(value)")
        return true
    }

    func setParametersToDefault() {
        dm.setParametersToDefault()
        procedural.setParametersToDefault()
        action.setParametersToDefault()
        imaginal.setParametersToDefault()
        reward = Model.rewardDefault
    }
    
    func loadParameters() {
        for (parameter,value) in parameters {
            setParameter(parameter, value: value)
        }
    }
    
    // The next section of code handles operators. This should be migrated to a separate class eventually
    
    /// List of chosen operators with time
    var previousOperators: [(Chunk,Double)] = []
    
    /**
    Update the Sji's between the current goal(s?) and the operators that have fired. Restrict to updating the goal in G1 for now.

    :param: payoff The payoff that will be distributed
    */
    func updateOperatorSjis(payoff: Double) {
        if !dm.goalOperatorLearning || reward == 0.0 { return } // only do this when switched on
        let goalChunk = formerBuffers["goal"]?.slotvals["slot1"]?.chunk() // take formerBuffers goal, because goal may have been replace by stop or nil
        if goalChunk == nil { return }
        for (operatorChunk,operatorTime) in previousOperators {
            let opReward = dm.defaultOperatorAssoc * (payoff - (time - operatorTime)) / reward
            if operatorChunk.assocs[goalChunk!.name] == nil {
                operatorChunk.assocs[goalChunk!.name] = (0.0, 0)
            }
            operatorChunk.assocs[goalChunk!.name]!.0 += dm.beta * (opReward - operatorChunk.assocs[goalChunk!.name]!.0)
            operatorChunk.assocs[goalChunk!.name]!.1++
            operatorChunk.addReference() // Also increase baselevel activation of the operator
            addToTrace("Updating assoc between \(goalChunk!.name) and \(operatorChunk.name) to \(operatorChunk.assocs[goalChunk!.name]!)")
        }
    }
    

    /**
    This function finds an operator. It can do this in several ways depending on the settings
    of the parameters compileOperators and retrieveOperatorsConditional.
    If retrieveOperatorsConditional is true, an operator is retrieved that is checked by the currently
    available productions. If successful, the operator is placed in the operator buffer.
    
    :returns: Whether an operator was successfully found
    */
    func findOperatorOrOperatorProduction() -> Bool {
        let retrievalRQ = Chunk(s: "operator", m: self)
        retrievalRQ.setSlot("isa", value: "operator")
        var (latency,opRetrieved) = dm.retrieve(retrievalRQ)
        if procedural.retrieveOperatorsConditional {
            var cfs = dm.conflictSet.sorted({ (item1, item2) -> Bool in
                let (_,u1) = item1
                let (_,u2) = item2
                return u1 > u2
            })
            if stepping {
                addToTrace("Conflict Set")
                for (chunk,activation) in cfs {
                    addToTrace("  \(chunk.name) A = \(activation)")
                }
            }
            var match = false
            var candidate: Chunk
            var activation: Double
            do {
                (candidate, activation) = cfs.removeAtIndex(0)
                let savedBuffers = buffers
                buffers["operator"] = candidate.copy()
                let inst = procedural.findMatchingProduction()
                match = procedural.fireProduction(inst, compile: false)
                buffers = savedBuffers
            } while !match && !cfs.isEmpty && cfs[0].1 > dm.retrievalThreshold
            if match {
                opRetrieved = candidate
                latency = dm.latency(activation)
            } else { opRetrieved = nil
                latency = dm.latency(dm.retrievalThreshold)
            }
        }
        time += latency
        if opRetrieved == nil { return false }
        if dm.goalOperatorLearning {
            let item = (opRetrieved!, time - latency)
            previousOperators.append(item)
        }
        addToTrace("*** Retrieved operator \(opRetrieved!.name) with spread \(opRetrieved!.spreadingActivation())")
        dm.addToFinsts(opRetrieved!)
        buffers["goal"]!.setSlot("last-operator", value: opRetrieved!)
        buffers["operator"] = opRetrieved!.copy()
        formerBuffers["operator"] = opRetrieved!

        
        return true
    }
    
    
    /**
    This function carries out productions for the current operator until it has a PRIM that fails, in
    which case it returns false, or until all the conditions of the operator have been tested and
    all actions have been carried out.
    */
    func carryOutProductionsUntilOperatorDone() -> Bool {
        var match: Bool = true
        var first: Bool = true
        while match && (buffers["operator"]?.slotvals["condition"] != nil || buffers["operator"]?.slotvals["action"] != nil) {
            let inst = procedural.findMatchingProduction()
            var pname = inst.p.name
            if pname.hasPrefix("t") {
                pname = dropFirst(pname)
            }
            addToTrace("Firing \(pname)")
            match = procedural.fireProduction(inst, compile: true)
            if first {
                time += procedural.productionActionLatency
                first = false
            } else {
            time += procedural.productionAndPrimLatency
            }
        }
        return match
    }
    
    func doAllModuleActions() {
        var latency = 0.0
        formerBuffers["retrievalH"] = buffers["retrievalH"]
        buffers["retrievalH"] = nil
        if buffers["retrievalR"] != nil {
            formerBuffers["retrievalR"] = buffers["retrievalR"]!
            let retrievalLatency = dm.action()
            latency = max(latency, retrievalLatency)
        }
        if buffers["imaginalN"] != nil {
            let actionLatency = imaginal.action()
            latency = max(latency, actionLatency)
        }
        if buffers["action"] != nil {
            formerBuffers["action"] = buffers["action"]!
            let actionLatency = action.action()
            latency = max(latency, actionLatency)
        }
        time += latency
    }
    
    /**
    Test whether the last action was the goal action
    
    :returns: True if goal is reached
    */
    func testGoalAction() -> Bool {
        if scenario.goalAction.isEmpty { return false }
        let action = formerBuffers["action"]
        if action == nil { return false }
        var count = 1
        for value in scenario.goalAction {
            if let actionValue = action!.slotvals["slot\(count++)"] {
                let compareValue = scenario.currentInput[value] ?? value  // if value is a variable, make substitution
                if actionValue.description != compareValue { return false }
            } else {
                return false
            }
        }
        return true
    }
    
    /**
    Execute a single operator by first finding one that matches, and then firing the necessary
    productions to execute it
    */
    func step() {
        if currentTask == nil { return }
        if !running {
            initializeNewTrial()
            return
        }
        dm.clearFinsts()
        var found: Bool = false
        formerBuffers = [:]
        formerBuffers["goal"] = buffers["goal"]?.copyLiteral()
        formerBuffers["imaginal"] = buffers["imaginal"]?.copyLiteral()
        formerBuffers["input"] = buffers["input"]?.copyLiteral()
        formerBuffers["retrievalH"] = buffers["retrievalH"]?.copyLiteral()
        commitToTrace(false)
        do {
            procedural.lastProduction = nil
            if !findOperatorOrOperatorProduction() { running = false ; return }
            found = carryOutProductionsUntilOperatorDone()
            if !found {
                let op = buffers["operator"]!
                addToTrace("Operator \(op.name) failed")
                commitToTrace(true)
                if dm.goalOperatorLearning {
                    previousOperators.removeLast()
                }
            }
        } while !found
        procedural.lastOperator = formerBuffers["operator"]
        commitToTrace(false)
        let op = buffers["operator"]!.name
        buffers["operator"] = nil
        doAllModuleActions()
        if scenario.nextEventTime != nil && scenario.nextEventTime! - 0.001 <= time {
            let retainTime = scenario.nextEventTime!
            scenario.makeTimeTransition(self)
            let result = buffers["input"]
            if result != nil {
            let slot1 = result!.slotvals["slot1"]?.description
            let slot2 = result!.slotvals["slot2"]?.description
            let slot3 = result!.slotvals["slot3"]?.description
            
            let dl = DataLine(eventType: "perception", eventParameter1: slot1 ?? "void", eventParameter2: slot2 ?? "void", eventParameter3: slot3 ?? "void", inputParameters: scenario.inputMappingForTrace, time: retainTime - startTime)
            outputData.append(dl)
            }
        }
        // We are done if the current action is the goal action, or there is no goal action and slot1 in the goal is set to stop
        if testGoalAction() || (scenario.goalAction.isEmpty && buffers["goal"]?.slotvals["slot1"] != nil && buffers["goal"]!.slotvals["slot1"]!.description == "stop")  {
            procedural.issueReward(40.0)
            updateOperatorSjis(reward)
            if let imaginalChunk = buffers["imaginal"] {
                dm.addToDM(imaginalChunk)
            }
            running = false
            resultAdd(time - startTime)
            let dl = DataLine(eventType: "trial-end", eventParameter1: "success", eventParameter2: "void", eventParameter3: "void", inputParameters: scenario.inputMappingForTrace, time: time - startTime)
            outputData.append(dl)
        } else {
            // Otherwise, we are also done if slot1 in the goal is set to stop and time runs out, but then there is no reward
            let maxTime = reward == 0.0 ? timeThreshold : reward
            if time - startTime > maxTime || (buffers["goal"]?.slotvals["slot1"] != nil && buffers["goal"]!.slotvals["slot1"]!.description == "stop") {
                procedural.issueReward(0.0)
                updateOperatorSjis(0.0)
                running = false
                resultAdd(time - startTime)
                let dl = DataLine(eventType: "trial-end", eventParameter1: "fail", eventParameter2: "void", eventParameter3: "void", inputParameters: scenario.inputMappingForTrace, time: time - startTime)
                outputData.append(dl)
            }
        }

    }
    
    func run() {
        if currentTask == nil { return }
        if !running { step() }
        while running  {
            step()
        }

        
    }
    
    func reset(taskNumber: Int?) {
        dm = Declarative(model: self)
        procedural = Procedural(model: self)
        buffers = [:]
        time = 0
        chunkIdCounter = 0
        running = false
        startTime = 0
        trace = ""
        waitingForAction = false
        currentTaskIndex = nil
        if taskNumber != nil {
            currentTaskIndex = taskNumber!
            scenario = PRScenario()
            parameters = []
            let parser = Parser(model: self, text: modelText, taskNumber: taskNumber!)
            setParametersToDefault()
            parser.parseModel()
            newResult()
        }
        for task in tasks {
            task.loaded = false
        }
        if currentTaskIndex != nil {
            tasks[currentTaskIndex!].loaded = true
        }
    }
    
    
    func loadOrReloadTask(i: Int) {
        if (i != currentTaskIndex) {
            modelText = String(contentsOfURL: tasks[i].filename, encoding: NSUTF8StringEncoding, error: nil)!
            currentTaskIndex = i
            if !tasks[i].loaded {
                scenario = PRScenario()
                parameters = []
                setParametersToDefault()
                parseCode(modelText,taskNumber: i)
                tasks[i].loaded = true
            }
            currentTask = tasks[i].name
//            println("Setting current task to \(currentTask!)")
            currentGoals = tasks[i].goalChunk
            currentGoalConstants = tasks[i].goalConstants
            parameters = tasks[i].parameters
            scenario = tasks[i].scenario
//            println("Setting scenario with startscreen \(scenario.startScreen.name)")
//            println("Setting parameters")
            setParametersToDefault()
            loadParameters()
//            println("Setting task index to \(i)")
            newResult()
            running = false
        }
    }
    
    func generateName(s1: String = "chunk") -> String {
        return s1 + "\(chunkIdCounter++)"
    }
    
    func generateNewChunk(s1: String = "chunk") -> Chunk {
        let name = generateName(s1: s1)
        let chunk = Chunk(s: name, m: self)
        return chunk
    }
    
    func stringToValue(s: String) -> Value {
        let possibleNumVal = string2Double(s)
        if possibleNumVal != nil {
            return Value.Number(possibleNumVal!)
        }
        if let chunk = self.dm.chunks[s] {
            return Value.Symbol(chunk)
        } else {
            return Value.Text(s)
        }
    }
}