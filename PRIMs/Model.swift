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
    var dm: Declarative!
    var procedural: Procedural!
    var imaginal: Imaginal!
    var action: Action!
    var operators: Operator!
//    lazy var dm: Declarative = { () -> Declarative in return Declarative(model: self) }()
//    lazy var procedural: Procedural = { () -> Procedural in return Procedural(model: self) }()
//    lazy var imaginal: Imaginal = { () -> Imaginal in return Imaginal(model: self) }()
//    lazy var action: Action = { () -> Action in return Action(model: self) }()
//    lazy var operators: Operator = { () -> Operator in return Operator(model: self) }()
    var buffers: [String:Chunk] = [:]
    var chunkIdCounter = 0
    var running = false
    var startTime: Double = 0.0
    var trace: [(Int,String)] {
        didSet {
            if !silent {
                NSNotificationCenter.defaultCenter().postNotificationName("TraceChanged", object: nil)
            }
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
    var modelCode: String?
    static let rewardDefault = 0.0
    /// Reward used for operator-goal association learning. Also determines maximum run time. Switched off when set to 0.0 (default)
    var reward: Double = rewardDefault
    let silent: Bool
    
//    struct Results {
        var modelResults: [[(Double,Double)]] = []
        var resultTaskNumber: [Int] = []
        var currentRow = -1
        var maxX = 0.0
        var maxY = 0.0
        var currentTrial = 1.0
        func resultAdd(y:Double) {
            if silent { return }
            let x = currentTrial
            currentTrial += 1.0
            if currentRow < modelResults.count {
                modelResults[currentRow].append((x,y))
                maxX = max(maxX, x)
            } else {
                let newItem: [(Double, Double)] = [(1.0,y)]
                modelResults.insert(newItem, atIndex: currentRow)
                currentTrial = 2.0
            }
            maxY = max(maxY, y)
        }
        func newResult() {
            if silent { return }
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
        
    init(silent: Bool) {
        trace = []
        self.silent = silent
        self.dm = Declarative(model: self)
        self.procedural = Procedural(model: self)
        self.imaginal = Imaginal(model: self)
        self.action = Action(model: self)
        self.operators = Operator(model: self)        
    }
    
    deinit {
        print("\(self) is deinitialized")
    }
    
    func loadModelWithString(filePath: NSURL) -> Bool {
        modelCode = try? String(contentsOfURL: filePath, encoding: NSUTF8StringEncoding)
        if modelCode != nil {
            scenario = PRScenario()
            parameters = []
            currentTaskIndex = tasks.count
            setParametersToDefault()
            if !parseCode(modelCode!,taskNumber: tasks.count) {
                reset(nil)
                return false
            }
        } else {
            return false
        }
        addTask(filePath)
        return true
    }

    
    var traceBuffer: [(Int,String)] = []
    
    /**
    Add an entry to the traceBuffer
    - parameter s: the string tot add
    - parameter level: the level of the entry
    */
    func addToTrace(s: String, level: Int) {
        if !silent && tracing {
        let timeString = String(format:"%.2f", time)
        traceBuffer.append((level,"\(timeString)  " + s))
//        trace += "\(timeString)  " + s + "\n"
        }
    }
    
    /**
    Add the items in the traceBuffer to the trace. Indented items in the trace belong
    to a part of the execution that has failed, and therefore also receive a higher level
    - parameter indented: should the added items be indented
   */
    func commitToTrace(indented: Bool) {
        if !silent {
            for (i,s) in traceBuffer {
                if indented {
                    trace.append((max(i, 3) ,"       " + s))
                } else {
                    trace.append((i,s))
                }
            }
        }
        traceBuffer = []
    }
    
    /**
    Add an item to trace so that it is always visible and do not gets a timestamp. This is used when parsing a model
    - parameter s: the string to add
    */
    func addToTraceField(s: String) {
        if !silent {
            trace.append((0,s))
        }
    }
    
    func clearTrace() {
        trace = []
    }
    
    /**
    Generate a text string that reflects the current trace
     - parameter maxLevel: Maximum level to include in the trace
     - returns: the String
    */
    func getTrace(maxLevel: Int) -> String {
        var result = ""
        for (level,s) in trace {
            if level <= maxLevel {
                result += s + "\n"
            }
        }
        return result
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
    
    func addTask(filePath: NSURL) {
        let newTask = Task(name: currentTask!, path: filePath)
        newTask.loaded = true
        newTask.goalChunk = currentGoals
        newTask.goalConstants = currentGoalConstants
        newTask.parameters = parameters
        newTask.scenario = scenario
        newTask.actions = action.actions
        tasks.append(newTask)
        running = false
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
        operators.previousOperators = []
    }

    func initializeNextTrial() {
        startTime = time
        buffers = [:]
        procedural.reset()
        buffers["goal"] = currentGoals?.copy()
        buffers["constants"] = currentGoalConstants?.copy()
        formerBuffers = [:]
        formerBuffers["goal"] = buffers["goal"]?.copyLiteral()
        formerBuffers["constants"] = buffers["constants"]?.copyLiteral()
        formerBuffers["input"] = buffers["input"]?.copyLiteral()
//        outputData = []
        operators.previousOperators = []
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
        case "goal-chunk-spreads:":
            dm.goalSpreadingByActivation = boolVal
        case "declarative-buffer-stuffing:":
            dm.declarativeBufferStuffing = boolVal
        case "retrieval-reinforces:":
            dm.retrievalReinforces = boolVal
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
            case "retrieval-activation:":
                dm.retrievalActivation = numVal!
            case "wm-activation:", "imaginal-activation:":
                dm.imaginalActivation = numVal!
            case "default-operator-assoc:":
                dm.defaultOperatorAssoc = numVal!
            case "default-inter-operator-assoc:":
                dm.defaultInterOperatorAssoc = numVal!
            case "default-operator-self-assoc:":
                dm.defaultOperatorSelfAssoc = numVal!
            case "production-prim-latency:":
                procedural.productionAndPrimLatency = numVal!
            case "perception-action-latency:":
                action.defaultPerceptualActionLatency = numVal!
            case "beta:":
                dm.beta = numVal!
            case "reward:":
                self.reward = numVal!
            case "procedural-reward:":
                procedural.proceduralReward = numVal!
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
    
    func doAllModuleActions() {
        var latency = 0.0
        formerBuffers["retrievalH"] = buffers["retrievalH"]
        buffers["retrievalH"] = nil
        if buffers["retrievalR"] != nil || dm.declarativeBufferStuffing {
            formerBuffers["retrievalR"] = buffers["retrievalR"]
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
    
    - returns: True if goal is reached
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
    
    func logInput(inputTime: Double) {
        let result = buffers["input"]
        if result != nil {
            let slot1 = result!.slotvals["slot1"]?.description
            let slot2 = result!.slotvals["slot2"]?.description
            let slot3 = result!.slotvals["slot3"]?.description
            
            let dl = DataLine(eventType: "perception", eventParameter1: slot1 ?? "void", eventParameter2: slot2 ?? "void", eventParameter3: slot3 ?? "void", inputParameters: scenario.inputMappingForTrace, time: inputTime - startTime)
            outputData.append(dl)
            
        }
    }
    
    
    func step() {
        if scenario.script == nil {
            oldStep()
        } else {
            if scenario.script!.scriptHasEnded()  {
                scenario.script!.reset()
            }
            if scenario.script!.scriptHasNotStarted() {
                initializeNewTrial()
            }
            scenario.script!.step(self)
        }
    }
    
    /**
        Run the current script and execute a single operator when there is a script
    */
    func newStep() {
        dm.clearFinsts()
        var found: Bool = false
        formerBuffers = [:]
        formerBuffers["goal"] = buffers["goal"]?.copyLiteral()
        formerBuffers["imaginal"] = buffers["imaginal"]?.copyLiteral()
        formerBuffers["input"] = buffers["input"]?.copyLiteral()
        formerBuffers["retrievalH"] = buffers["retrievalH"]?.copyLiteral()
        formerBuffers["constants"] = buffers["constants"]?.copyLiteral()
        commitToTrace(false)
        repeat {
            procedural.lastProduction = nil
            if !operators.findOperator() {
                if scenario.nextEventTime == nil {
                    running = false
                    //                    procedural.issueReward(0.0)
                    operators.updateOperatorSjis(0.0)
                    let dl = DataLine(eventType: "trial-end", eventParameter1: "fail", eventParameter2: "void", eventParameter3: "void", inputParameters: scenario.inputMappingForTrace, time: time - startTime)
                    outputData.append(dl)
                    return
                } else {
                    time = scenario.nextEventTime!
                    logInput(time)
                    return
                }
            }
            found = operators.carryOutProductionsUntilOperatorDone()
            if !found {
                let op = buffers["operator"]!
                addToTrace("Operator \(op.name) failed", level: 2)
                commitToTrace(true)
                buffers["goal"] = formerBuffers["goal"]
                buffers["imaginal"] = formerBuffers["imaginal"]
                buffers["input"] = formerBuffers["input"]
                buffers["retrievalH"] = formerBuffers["retrievalH"]
                buffers["constants"] = formerBuffers["constants"]
                if dm.goalOperatorLearning {
                    operators.previousOperators.removeLast()
                }
                procedural.clearRewardTrace()  // Don't reward productions that didn't work
            }
        } while !found
        procedural.issueReward(procedural.proceduralReward) // Have to make this into a setable parameter
        procedural.lastOperator = formerBuffers["operator"]
        commitToTrace(false)
        //        let op = buffers["operator"]!.name
        buffers["operator"] = nil
        doAllModuleActions()
    }
    
    
    /**
    Execute a single operator by first finding one that matches, and then firing the necessary
    productions to execute it. This version is used when there is no script
    */
    func oldStep() {
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
        formerBuffers["constants"] = buffers["constants"]?.copyLiteral()
        commitToTrace(false)
        repeat {
            procedural.lastProduction = nil
            if !operators.findOperator() {
                if scenario.nextEventTime == nil {
                    running = false
//                    procedural.issueReward(0.0)
                    operators.updateOperatorSjis(0.0)
                    let dl = DataLine(eventType: "trial-end", eventParameter1: "fail", eventParameter2: "void", eventParameter3: "void", inputParameters: scenario.inputMappingForTrace, time: time - startTime)
                    outputData.append(dl)
                    return
                } else {
                    time = scenario.nextEventTime!
                    scenario.makeTimeTransition(self)
                    logInput(time)
                    return
                }
            }
            found = operators.carryOutProductionsUntilOperatorDone()
            if !found {
                let op = buffers["operator"]!
                addToTrace("Operator \(op.name) failed", level: 2)
                commitToTrace(true)
                buffers["goal"] = formerBuffers["goal"]
                buffers["imaginal"] = formerBuffers["imaginal"]
                buffers["input"] = formerBuffers["input"]
                buffers["retrievalH"] = formerBuffers["retrievalH"]
                buffers["constants"] = formerBuffers["constants"]
                if dm.goalOperatorLearning {
                    operators.previousOperators.removeLast()
                }
                procedural.clearRewardTrace()  // Don't reward productions that didn't work
            }
        } while !found
        procedural.issueReward(procedural.proceduralReward) // Have to make this into a setable parameter
        procedural.lastOperator = formerBuffers["operator"]
        commitToTrace(false)
//        let op = buffers["operator"]!.name
        buffers["operator"] = nil
        doAllModuleActions()
        if scenario.nextEventTime != nil && scenario.nextEventTime! - 0.001 <= time {
            let retainTime = scenario.nextEventTime!
            scenario.makeTimeTransition(self)
            logInput(retainTime)
        }
        // We are done if the current action is the goal action, or there is no goal action and slot1 in the goal is set to stop
        if testGoalAction() || (scenario.goalAction.isEmpty && buffers["goal"]?.slotvals["slot1"] != nil && buffers["goal"]!.slotvals["slot1"]!.description == "stop")  {
//            procedural.issueReward(40.0)
            operators.updateOperatorSjis(reward)
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
//                procedural.issueReward(0.0)
                operators.updateOperatorSjis(0.0)
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
//        trace = []
        waitingForAction = false
        currentTaskIndex = nil
        operators.reset()
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
            modelText = try! String(contentsOfURL: tasks[i].filename, encoding: NSUTF8StringEncoding)
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
            action.actions = tasks[i].actions
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
        let name = generateName(s1)
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