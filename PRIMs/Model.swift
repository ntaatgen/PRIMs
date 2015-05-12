//
//  Model.swift
//  actr
//
//  Created by Niels Taatgen on 3/1/15.
//  Copyright (c) 2015 Niels Taatgen. All rights reserved.
//

import Foundation



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
    var inputs: [Chunk] = []
    var currentTask: String? = nil /// What is the name of the current task
    var currentGoals: Chunk? = nil /// Chunk that has the goals to implement the task
    var currentGoalConstants: Chunk? = nil
    var tracing: Bool = true
    var parameters: [(String,String)] = []
    var scenario = PRScenario()
    
//    struct Results {
        var modelResults: [[(Double,Double)]] = [[]]
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
            }
        }
    func clearResults() {
        modelResults = [[]]
        currentRow = 0
        maxX = 0.0
        maxY = 0.0
        currentTrial = 1.0
    }
        
//    }

    func reset() {
        dm = Declarative(model: self)
        procedural = Procedural(model: self)
        buffers = [:]
        time = 0
        chunkIdCounter = 0
        running = false
        startTime = 0
        trace = ""
        waitingForAction = false
        inputs = []
        let parser = Parser(model: self, text: modelText)
        parser.parseModel()
        newResult()
    }

    init() {
        trace = ""
    }
    
    func addToTrace(s: String) {
        if tracing {
        let timeString = String(format:"%.2f", time)
        println("\(timeString)  " + s)
        trace += "\(timeString)  " + s + "\n"
        }
    }
    
    func clearTrace() {
        trace = ""
    }
    
    func parseCode(modelCode: String) {
        let parser = Parser(model: self, text: modelCode)
        parser.parseModel()
        modelText = modelCode
        newResult()
    }
    

    func initializeNewTrial() {
        startTime = time
        buffers = [:]
        procedural.reset()
        buffers["goal"] = currentGoals?.copy()
        buffers["constants"] = currentGoalConstants?.copy()
        if !inputs.isEmpty {
            let trial = inputs[Int(arc4random_uniform(UInt32(inputs.count)))]
            buffers["input"] = trial
        }
        action.initTask()
        running = true
        clearTrace()
    }
    
    func setParameter(parameter: String, value: String) -> Bool {
        let numVal = NSNumberFormatter().numberFromString(value)?.doubleValue
        let boolVal = (value != "nil")
        switch parameter {
        case ":imaginal-delay":
            imaginal.imaginalLatency = numVal!
        case ":imaginal-autoclear":
            imaginal.autoClear = boolVal
        case ":egs":
            procedural.utilityNoise = numVal!
        case ":alpha":
            procedural.alpha = numVal!
        case ":nu":
            procedural.defaultU = numVal!
        case ":primU":
            procedural.primU = numVal!
        case ":utility-retrieve-operator":
            procedural.utilityRetrieveOperator = numVal!
        case ":dat":
            procedural.productionActionLatency = numVal!
        case ":bll":
            dm.baseLevelDecay = numVal!
        case ":ol":
            dm.optimizedLearning = boolVal
        case ":mas":
            dm.maximumAssociativeStrength = numVal!
        case ":rt":
            dm.retrievalThreshold = numVal!
        case ":lf":
            dm.latencyFactor = numVal!
        case ":mp":
            dm.misMatchPenalty = numVal!
        case ":ans":
            dm.activationNoise = numVal!
        case ":default-operator-assoc":
            dm.defaultOperatorAssoc = numVal!
        default: return false
        }
        println("Parameter \(parameter) has value \(value)")
        return true
    }

    func loadParameters() {
        for (parameter,value) in parameters {
            setParameter(parameter, value: value)
        }
    }

    /**
    This function finds an operator. It can do this in several ways depending on the settings
    of the parameters compileOperators and retrieveOperatorsConditional.
    If compileOperators is true, this means that an operator can be compiled into a production. In that case
    this function can fire a production that sets the operator, and carries out some or all of it.
    If retrieveOperatorsConditional is true, an operator is retrieved that is checked by the currently
    available productions.
    */
    func findOperatorOrOperatorProduction() -> Bool {
        let opInst = procedural.compileOperators ? procedural.findOperatorProduction() : nil
        if opInst == nil {
            let retrievalRQ = Chunk(s: "operator", m: self)
            retrievalRQ.setSlot("isa", value: "operator")
            var (latency,opRetrieved) = dm.retrieve(retrievalRQ)
            if procedural.retrieveOperatorsConditional {
                var cfs = dm.conflictSet.sorted({ (item1, item2) -> Bool in
                    let (_,u1) = item1
                    let (_,u2) = item2
                    return u1 > u2
                })
//                println("Conflict set \(cfs)")
                var match = false
                var candidate: Chunk
                var activation: Double
                do {
                    (candidate, activation) = cfs.removeAtIndex(0)
                    //                        println("Trying operator \(candidate.name)")
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
            addToTrace("*** Retrieved operator \(opRetrieved!.name)")
            dm.addToFinsts(opRetrieved!)
            buffers["operator"] = opRetrieved!.copy()
            procedural.lastOperator = opRetrieved!
        } else {
            addToTrace("Firing operator production \(opInst!.p.name)")
            procedural.fireProduction(opInst!, compile: true)
            time += 0.05
        }
        return true
    }
    
    
    /**
    This function carries out productions for the current operator until it has a PRIM that fails, in
    which case it returns false, or until all the conditions of the operator have been tested and
    all actions have been carried out.
    */
    func carryOutProductionsUntilOperatorDone() -> Bool {
        var match: Bool = true
        while match && (buffers["operator"]?.slotvals["condition"] != nil || buffers["operator"]?.slotvals["action"] != nil) {
            let inst = procedural.findMatchingProduction()
            addToTrace("Firing \(inst.p.name)")
            match = procedural.fireProduction(inst, compile: true)
            time += procedural.productionActionLatency
        }
        return match
    }
    
    func doAllModuleActions() {
        var latency = 0.0
        buffers["retrievalH"] = nil
        if buffers["retrievalR"] != nil {
            let retrievalLatency = dm.action()
            latency = max(latency, retrievalLatency)
        }
        if buffers["imaginalN"] != nil {
            let actionLatency = imaginal.action()
            latency = max(latency, actionLatency)
        }
        if buffers["action"] != nil {
            let actionLatency = action.action()
            latency = max(latency, actionLatency)
        }
        time += latency
    }
    
    /**
    Execute a single operator by first finding one that matches, and then firing the necessary
    productions to execute it
    */
    func step() {
        if currentTask == nil { return }
        if !running {
            initializeNewTrial()
        }
        dm.clearFinsts()
        var found: Bool = false
        do {
            procedural.lastProduction = nil
            if !findOperatorOrOperatorProduction() { running = false ; return }
            found = carryOutProductionsUntilOperatorDone()
            if !found {
                let op = buffers["operator"]!
                addToTrace("Operator \(op.name) failed")
            }
        } while !found
        buffers["operator"] = nil
        doAllModuleActions()
        if buffers["goal"]!.slotvals["slot1"]!.text()! == "stop" {
            procedural.issueReward(40.0)
            running = false
//            println("New item = \(newItem)")
            resultAdd(time - startTime)
        }
    }
    
    func run() {
        if currentTask == nil { return }
        if !running { step() }
        while running {
            step()
        }
        
        
    }
    
    func generateNewChunk(s1: String = "chunk") -> Chunk {
        let name = s1 + "\(chunkIdCounter++)"
        let chunk = Chunk(s: name, m: self)
        return chunk
    }
    
    func stringToValue(s: String) -> Value {
        let possibleNumVal = NSNumberFormatter().numberFromString(s)?.doubleValue
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