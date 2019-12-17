//
//  Model.swift
//  actr
//
//  Created by Niels Taatgen on 3/1/15.
//  Copyright (c) 2015 Niels Taatgen. All rights reserved.
//

import Foundation

struct DataLine {
    var eventType: String = "void"
    var eventParameter1: String = "void"
    var eventParameter2: String = "void"
    var eventParameter3: String = "void"
    var inputParameters: [String] = ["void","void","void","void","void"]
    var firings: Int = 0
    var time: Double

    init(eventType: String, eventParameter1: String, eventParameter2: String, eventParameter3: String, inputParameters: [String], time: Double, firings: Int) {
        self.eventType = eventType != "" ? eventType : "void"
        self.eventParameter1 = eventParameter1 != "" ? eventParameter1 : "void"
        self.eventParameter2 = eventParameter2 != "" ? eventParameter2 : "void"
        self.eventParameter3 = eventParameter3 != "" ? eventParameter3 : "void"
        self.time = time
        self.inputParameters = inputParameters != [] ? inputParameters : ["void","void","void","void","void"]
        self.firings = firings
    }
}

class Model: NSObject, NSCoding {
    var time: Double = 0
    var dm: Declarative!
    var procedural: Procedural!
    var imaginal: Imaginal!
    var action: Action!
    var operators: Operator!
    var temporal: Temporal!
    weak var conflictSet: ConflictSetTrace? = nil
    var buffers: [String:Chunk] = [:] {
        didSet {
            if buffers["imaginal"] != oldValue["imaginal"] {
                let s = buffers["imaginal"]
//                print("***Imaginal buffer changed to \(s)")
                if s != nil {
//                    print("parent is: \(s!.parent)")
                }
            }
        }
        
    }
//    var bufferStack: [String:[Chunk]] = [:]
    var chunkIdCounter = 0
    var running = false
    var fallingThrough = false
    var startTime: Double = 0.0
    /// Is there a valid model in memory? If not don't respond to run
    var valid = false
    var trace: [(Int,String)] {
        didSet {
            if !silent {
                NotificationCenter.default.post(name: Notification.Name(rawValue: "TraceChanged"), object: nil)
            }
        }
    }
    var waitingForAction: Bool = false {
        didSet {
            if waitingForAction == true {
//                println("Posted Action notification")
                NotificationCenter.default.post(name: Notification.Name(rawValue: "Action"), object: nil)
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
    /// Batch Parameters
    var batchMode: Bool
    var batchParameters: [String] = []
    /// Maximum time to run the model
    var timeThreshold = 200.0
    var outputData: [DataLine] = []
    //var batchTraceData: [(Double, String, String)] = []
    var batchTrace: Bool = false
    var formerBuffers: [String:Chunk] = [:]
    var modelCode: String?
    // Model-level parameters
    static let rewardDefault = 0.0
    /// Reward used for operator-goal association learning. Also determines maximum run time. Switched off when set to 0.0 (default)
    var reward: Double = rewardDefault
    static let operatorLearningDefault = false
    /// Switch for operator learning
    var operatorLearning = operatorLearningDefault
    /// Counter to count production firings
    var firings: Int = 0
    
    var traceAllOperators = false
    let silent: Bool
    
//    struct Results {
        var modelResults: [[(Double,Double)]] = []
        var resultTaskNumber: [Int] = []
        var currentRow = -1
        var maxX = 0.0
        var maxY = 0.0
        var currentTrial = 1.0
        var customPoints = false
        var averageWindow = 1
        var graphTitle: String? = nil
        func resultAdd(_ y:Double) {
            if silent { return }
            let x = currentTrial
            currentTrial += 1.0
            if currentRow < modelResults.count {
                modelResults[currentRow].append((x,y))
                maxX = max(maxX, x)
            } else {
                let newItem: [(Double, Double)] = [(1.0,y)]
                modelResults.insert(newItem, at: currentRow)
                currentTrial = 2.0
            }
            maxY = max(maxY, y)
            customPoints = false
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
        
    init(silent: Bool, batchMode: Bool) {
        trace = []
        self.silent = silent
        self.batchMode = batchMode
     
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard let dm = aDecoder.decodeObject(forKey: "dm") as? Declarative,
                let procedural = aDecoder.decodeObject(forKey: "procedural") as? Procedural
            else { return nil }
        self.init(silent: false, batchMode: false)
        self.dm = dm
        self.procedural = procedural
        self.imaginal = Imaginal(model: self)
        self.action = Action(model: self)
        self.operators = Operator(model: self)
        self.time = aDecoder.decodeDouble(forKey: "time")
        self.temporal = Temporal(model:self)
    }
    
    convenience init(silent: Bool) {
        self.init(silent: silent, batchMode: false)
        self.dm = Declarative(model: self)
        self.procedural = Procedural(model: self)
        self.imaginal = Imaginal(model: self)
        self.action = Action(model: self)
        self.operators = Operator(model: self)
        self.temporal = Temporal(model:self)
    }
    
    convenience init(batchMode: Bool) {
        self.init(silent: true, batchMode: batchMode)
        self.dm = Declarative(model: self)
        self.procedural = Procedural(model: self)
        self.imaginal = Imaginal(model: self)
        self.action = Action(model: self)
        self.operators = Operator(model: self)
        self.temporal = Temporal(model:self)
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(self.dm, forKey: "dm")
        coder.encode(self.procedural, forKey: "procedural")
        coder.encode(self.time, forKey: "time")
    }

    
    func loadModelWithString(_ filePath: URL) -> Bool {
        modelCode = try? String(contentsOf: filePath, encoding: String.Encoding.utf8)
        if modelCode != nil {
            scenario = PRScenario()
            parameters = []
            currentTaskIndex = tasks.count
            setParametersToDefault()
            if !parseCode(modelCode!,taskNumber: tasks.count) {
                valid = false
                reset(nil)
                return false
            }
            
        } else {
            valid = false
            return false
        }
        addTask(filePath)
        valid = true
        
        /// This just for testing purposes
        for (_, chunk) in dm.chunks {
            if chunk.type == "operator" {
                let optest = Op(chunk: chunk)
                let result = optest.buildChunk(model: self)
                print(result.description)
            }
        }
        
        
        return true
    }

    
    var traceBuffer: [(Int,String)] = []
    
    /**
    Add an entry to the traceBuffer
    - parameter s: the string tot add
    - parameter level: the level of the entry
    */
    func addToTrace(_ s: String, level: Int) {
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
    func commitToTrace(_ indented: Bool) {
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
    Add an item to trace so that it is always visible and does not get a timestamp. This is used when parsing a model
    - parameter s: the string to add
    */
    func addToTraceField(_ s: String) {
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
    func getTrace(_ maxLevel: Int) -> String {
        var result = ""
        for (level,s) in trace {
            if level <= maxLevel {
                result += s + "\n"
            }
        }
        return result
    }
    
    /* Add to batch trace
     * Input parameters: timestamp (double) and addToTrace (string)
     * No return parameter
     */
    /*
    func addToBatchTrace(_ timestamp: Double, type: String, addToTrace: String) {
        batchTraceData += [(timestamp, type, addToTrace)]
    }
    */
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

    func findTask(_ taskName: String) -> Int? {
        for i in 0..<tasks.count {
            if tasks[i].name == taskName {
                return i
            }
        }
        return nil
    }
    
    
    func parseCode(_ modelCode: String, taskNumber: Int) -> Bool {
        let parser = Parser(model: self, text: modelCode, taskNumber: taskNumber)
        let result = parser.parseModel()
        if result {
            modelText = modelCode
            newResult()
            if scenario.initScript != nil {
//                print("Running init script")
                scenario.initScript!.reset()
                scenario.initScript!.step(self)
            }
        }
        return result
    }
    
    func addTask(_ filePath: URL) {
        let newTask = Task(name: currentTask!, path: filePath)
        newTask.loaded = true
        newTask.goalChunk = currentGoals
        newTask.goalConstants = currentGoalConstants
        newTask.parameters = parameters
        newTask.scenario = scenario
        newTask.actions = action.actions
        tasks.append(newTask)
        running = false
        fallingThrough = false
    }
    

    func initializeNewTrial() {
        startTime = time
        fallingThrough = false
        buffers = [:]
//        bufferStack = [:]
        procedural.reset()
        buffers["goal"] = currentGoals?.copyChunk()
        buffers["constants"] = currentGoalConstants?.copyChunk()
        formerBuffers = [:]
        formerBuffers["goal"] = buffers["goal"]?.copyLiteral()
        formerBuffers["constants"] = buffers["constants"]?.copyLiteral()
        action.initTask()
        formerBuffers["input"] = buffers["input"]
        running = true
        clearTrace()
        outputData = []
        operators.previousOperators = []
        firings = 0
        if scenario.script != nil {
            scenario.script!.reset()
        }
        }

    func initializeNextTrial() {
        startTime = time
        fallingThrough = false
        buffers = [:]
//        bufferStack = [:]
        procedural.reset()
        buffers["goal"] = currentGoals?.copyChunk()
        buffers["constants"] = currentGoalConstants?.copyChunk()
        formerBuffers = [:]
        formerBuffers["goal"] = buffers["goal"]?.copyLiteral()
        formerBuffers["constants"] = buffers["constants"]?.copyLiteral()
        formerBuffers["input"] = buffers["input"]
//        outputData = []
        operators.previousOperators = []
        firings = 0
    }
    
    func setParameter(_ parameter: String, value: String) -> Bool {
        let numVal = string2Double(value)
        let boolVal = (value != "nil")
        switch parameter {
//        case "imaginal-autoclear:":
//            imaginal.autoClear = boolVal
        case "ol:":
            dm.optimizedLearning = boolVal
        case "goal-operator-learning:", "skill-operator-learning:":
            dm.goalOperatorLearning = boolVal
        case "context-operator-learning:":
             dm.contextOperatorLearning = boolVal
        case "inter-operator-learning:":
            dm.interOperatorLearning = boolVal
        case "goal-chunk-spreads:":
            dm.goalSpreadingByActivation = boolVal
        case "declarative-buffer-stuffing:":
            dm.declarativeBufferStuffing = boolVal
        case "retrieval-reinforces:":
            dm.retrievalReinforces = boolVal
        case "pm:":
            dm.partialMatching = boolVal
        case "batch-trace:":
            batchTrace = boolVal
        case "blending:":
            dm.blending = boolVal
        case "opc:":
            operatorLearning = boolVal
        case "operator-bll:":
            dm.operatorBaselevelLearning = boolVal
        case "default-activation:":
            if value == "nil" {
                dm.defaultActivation = nil
            } else if numVal != nil {
                dm.defaultActivation = numVal!
            } else {
                return false
            }
            dm.defaultActivation = numVal!
        //case "batch-trace":
        //    if batchMode {
        //        batchTrace = true
        //    }
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
//            case "utility-retrieve-operator:":
//                procedural.utilityRetrieveOperator = numVal!
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
            case "new-pm-pow:":
                dm.newPartialMatchingPow = numVal!
            case "new-pm-exp:":
                dm.newPartialMatchingPow = numVal!
            case "time-t0:":
                temporal.timeT0 = numVal!
            case "time-a:":
                temporal.timeA = numVal!
            case "time-b:":
                temporal.timeB = numVal!
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
        temporal.setParametersToDefault()
        reward = Model.rewardDefault
        operatorLearning = Model.operatorLearningDefault
    }
    
    func loadParameters() {
        for (parameter,value) in parameters {
            _ = setParameter(parameter, value: value)
        }
    }
    
    func doAllModuleActions() {
        var latency = 0.0
        formerBuffers["retrievalH"] = buffers["retrievalH"]
        // If the last operator did not have any actions, we do not clear the retrieval buffer.
        // In that way, operator compilation can combine it with a subsequent operator.
        if procedural.lastOperator == nil || procedural.lastOperator!.slotvals["action"] != nil {
            buffers["retrievalH"] = nil
        }
//        bufferStack["retrievalH"] = nil
        if buffers["retrievalR"] != nil || dm.declarativeBufferStuffing {
            formerBuffers["retrievalR"] = buffers["retrievalR"]
            let retrievalLatency = dm.action()
            latency = max(latency, retrievalLatency)
        }
        if imaginal.hasToDoAction {
            let actionLatency = imaginal.action()
            latency = max(latency, actionLatency)
        }
        if buffers["action"] != nil {
            formerBuffers["action"] = buffers["action"]!
            let actionLatency = action.action()
            latency = max(latency, actionLatency)
        }
        if buffers["temporal"] != nil {
            temporal.action()
        }
        time += latency
        if buffers["temporal"] != nil {
            print("Updating timer")
            temporal.updateTimer()
        }
    }
    
    /**
    Test whether the last action was the goal action
    
    - returns: True if goal is reached
    */
/*    func testGoalAction() -> Bool {
//        if scenario.goalAction.isEmpty { return false }
        let action = formerBuffers["action"]
        if action == nil { return false }
        var count = 1
        for value in scenario.goalAction {
            if let actionValue = action!.slotvals["slot\(count)"] {
                let compareValue = scenario.currentInput[value] ?? value  // if value is a variable, make substitution
                if actionValue.description != compareValue { return false }
            } else {
                return false
            }
            count += 1
        }
        return true
    }
*/
    func logInput(_ inputTime: Double) {
        let result = buffers["input"]
        if result != nil {
            let slot1 = result!.slotvals["slot1"]?.description
            let slot2 = result!.slotvals["slot2"]?.description
            let slot3 = result!.slotvals["slot3"]?.description
            
            let dl = DataLine(eventType: "perception", eventParameter1: slot1 ?? "void", eventParameter2: slot2 ?? "void", eventParameter3: slot3 ?? "void", inputParameters: scenario.inputMappingForTrace, time: inputTime - startTime, firings: firings)
            outputData.append(dl)
            firings = 0
        }
    }
    
    /**
        Perform a single step (one operator). This function handles control through the script, which in turn calls the newStep function.
    */
    func step() {
        guard valid else { return } /// make sure we have a valid model to run
            if scenario.script!.scriptHasEnded()  {
                scenario.script!.reset()
            }
            if scenario.script!.scriptHasNotStarted() {
                initializeNewTrial()
            }
            scenario.script!.step(self)
    }
    
    
    var stillNeedToDoModuleActions = false
    var halfStep = true
    
    /**
        Run the current script and execute a single operator when there is a script.
        This function is called from the script
    */
    func newStep() {
        if stillNeedToDoModuleActions {
            doAllModuleActions()
            stillNeedToDoModuleActions = false
            return
        }
        dm.clearFinsts()
        var found: Bool = false
//        let lastOperator = formerBuffers["operator"]
//        var bufferStackCopy = bufferStack
        formerBuffers = [:]
        formerBuffers["goal"] = buffers["goal"]?.copyLiteral()
        formerBuffers["imaginal"] = buffers["imaginal"]
        formerBuffers["input"] = buffers["input"]
        formerBuffers["retrievalH"] = buffers["retrievalH"]?.copyLiteral()
        formerBuffers["constants"] = buffers["constants"]?.copyLiteral()
        commitToTrace(false)
        repeat {
            procedural.lastProduction = nil
            if !operators.findOperator() {
                if scenario.nextEventTime == nil {
                    running = false
                    fallingThrough = true
                    //                    procedural.issueReward(0.0)
                    operators.updateOperatorSjis(0.0)
                    let dl = DataLine(eventType: "trial-end", eventParameter1: "fail", eventParameter2: "void", eventParameter3: "void", inputParameters: scenario.inputMappingForTrace, time: time - startTime, firings: firings)
                    outputData.append(dl)
                    firings = 0
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
                if !silent {
                    addToTrace("Operator \(op.name) failed", level: 2)
                }
                commitToTrace(true)
                buffers["goal"] = formerBuffers["goal"]
                buffers["imaginal"] = formerBuffers["imaginal"]
                buffers["input"] = formerBuffers["input"]
                buffers["retrievalH"] = formerBuffers["retrievalH"]
                buffers["constants"] = formerBuffers["constants"]
//                bufferStack = bufferStackCopy  // This is not perfect because other Chunks may have been modified
                operators.removeLastOperatorRecord()
                procedural.clearRewardTrace()  // Don't reward productions that didn't work
            }
        } while !found
        procedural.issueReward(procedural.proceduralReward)
        procedural.lastOperator = formerBuffers["operator"]
        if traceAllOperators {
            //model.buffers["goal"]!.setSlot("last-operator", value: opRetrieved!)
            //addToBatchTrace(time - startTime, type: "operator", addToTrace: "\(procedural.lastOperator!.name)")
            if let lastoperator = buffers["goal"]?.slotvals["last-operator"]?.description {
            let dl = DataLine(eventType: "operator", eventParameter1: lastoperator, eventParameter2: "void", eventParameter3: "void", inputParameters: scenario.inputMappingForTrace, time: time - startTime, firings: firings)
            outputData.append(dl)
            firings = 0
            }
        }
        commitToTrace(false)
        buffers["operator"] = nil
        if halfStep {
            stillNeedToDoModuleActions = true
            return
        }
        doAllModuleActions()
    }
    
 
    func run() {
        if currentTask == nil { return }
        if !running { step() }
        while running  {
            step()
        }
        }
    
    func reset(_ taskNumber: Int?) {
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
        imaginal.reset()
        stillNeedToDoModuleActions = false
        if taskNumber != nil {
            currentTaskIndex = taskNumber!
            scenario = PRScenario()
            parameters = []
            let parser = Parser(model: self, text: modelText, taskNumber: taskNumber!)
            setParametersToDefault()
            _ = parser.parseModel()
            if scenario.initScript != nil {
                scenario.initScript!.reset()
                scenario.initScript!.step(self)
                print("Running init script")
            }
            newResult()
        }
        for task in tasks {
            task.loaded = false
        }
        if currentTaskIndex != nil {
            tasks[currentTaskIndex!].loaded = true
        }
    }
    
    
    func loadOrReloadTask(_ i: Int) {
        if (i != currentTaskIndex) {
            modelText = try! String(contentsOf: tasks[i].filename as URL, encoding: String.Encoding.utf8)
            currentTaskIndex = i
            if !tasks[i].loaded {
                scenario = PRScenario()
                parameters = []
                setParametersToDefault()
                valid = parseCode(modelText,taskNumber: i)
                tasks[i].loaded = true
            }
            currentTask = tasks[i].name
            currentGoals = tasks[i].goalChunk
            currentGoalConstants = tasks[i].goalConstants
            parameters = tasks[i].parameters
            scenario = tasks[i].scenario
            action.actions = tasks[i].actions
            setParametersToDefault()
            loadParameters()
            newResult()
            running = false
        }
    }
    
    func generateName(_ s1: String = "chunk") -> String {
        chunkIdCounter += 1
        return s1 + "\(chunkIdCounter - 1)"
    }
    
    func generateNewChunk(_ s1: String = "chunk") -> Chunk {
        let name = generateName(s1)
        let chunk = Chunk(s: name, m: self)
        return chunk
    }
    
    func stringToValue(_ s: String) -> Value {
        let possibleNumVal = string2Double(s)
        if possibleNumVal != nil {
            return Value.Number(possibleNumVal!)
        }
        if let chunk = self.dm.chunks[s] {
            return Value.symbol(chunk)
        } else {
            return Value.Text(s)
        }
    }
}
