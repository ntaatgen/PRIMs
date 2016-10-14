//
//  FruchtermanReingold.swift
//  PRIMs
//
//  Created by Niels Taatgen on 5/12/15.
//  Copyright (c) 2015 Niels Taatgen. All rights reserved.
//

import Foundation

class Node {
    let name: String
    var x: Double = 0.0
    var y: Double = 0.0
    var dx: Double = 0.0
    var dy: Double = 0.0
    var taskNumber: Int = -2 // White node
    var rank = 0.0
    var taskNode = false
    var labelVisible = false
    var shortName: String
    var definedByTask: Int? = nil
    var halo = false
    init(name: String) {
        self.name = name
        self.shortName = name
    }
}

class Edge {
    let from: Node
    let to: Node
    init(from: Node, to: Node) {
        self.from = from
        self.to = to
    }
}



class FruchtermanReingold {
    var nodes: [String:Node] = [:]
    var keys: [String] = []
    var nodeToIndex: [String:Int] = [:]
    var edges: [Edge] = []
    var W: Double
    var H: Double
    let iterations = 100
    var constantC = 0.3
    var wallRepulsionMultiplier = 2.0
    var area: Double {
        get {
            return W * H
        }
    }
    var k: Double {
        get {
            if nodes.count > 0 {
                return constantC * sqrt(area/Double(nodes.count))
            } else {
                return 0.0
            }
        }
    }
    
    init(W: Double, H: Double) {
        self.W = W
        self.H = H
    }
    
    func attractionForce(_ x: Double) -> Double {
        return pow(x,2)/k
    }
    
    func repulsionForce(_ z: Double) -> Double {
        return pow(k,2) / z
    }

    func vectorLength(_ x: Double, y: Double) -> Double {
        return sqrt(pow(x,2)+pow(y,2))
    }
    
    func rescale(_ newW: Double, newH: Double) {
        for (_,node) in nodes {
            node.x = node.x * (newW/W)
            node.y = node.y * (newH/H)
        }
        W = newW
        H = newH
    }
    
    func calculate() {
        DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.low).async { () -> Void in
        var maxRank = 0.0
        for (_,node) in self.nodes {
            node.x = Double(Int(arc4random_uniform(UInt32(self.W))))
            node.y = Double(Int(arc4random_uniform(UInt32(self.H))))
            maxRank = max(maxRank,node.rank)
            
        }
        let rankStep = (self.H - 30) / (maxRank - 1)
        for i in 0..<self.iterations {
            let temperature = 0.1 * max(self.W,self.H) * Double(self.iterations - i)/Double(self.iterations)
            // Calculate repulsive forces
            for (_,node) in self.nodes {
                node.dx = 0
                node.dy = 0
                for (_,node2) in self.nodes {
                    if node !== node2 {
                        let deltaX = node.x - node2.x
                        let deltaY = node.y - node2.y
                        let deltaLength = self.vectorLength(deltaX, y: deltaY)
                        node.dx += (deltaX / deltaLength) * self.repulsionForce(deltaLength)
                        node.dy += (deltaY / deltaLength) * self.repulsionForce(deltaLength)
                    }
                }
                // repulsion of walls
                node.dx += self.wallRepulsionMultiplier * self.repulsionForce(node.x + 1)
                node.dx -= self.wallRepulsionMultiplier * self.repulsionForce(self.W + 1 - node.x)
                node.dy += self.wallRepulsionMultiplier * self.repulsionForce(node.y + 1)

                node.dy -= self.wallRepulsionMultiplier * self.repulsionForce(self.H + 1 - node.y)
                
            }
            // calculate attractive forces
            
            for edge in self.edges {
                let deltaX = edge.from.x - edge.to.x
                let deltaY = edge.from.y - edge.to.y
                let deltaLength = self.vectorLength(deltaX, y: deltaY)
                edge.from.dx -= (deltaX / deltaLength) * self.attractionForce(deltaLength)
                edge.from.dy -= (deltaY / deltaLength) * self.attractionForce(deltaLength)
                edge.to.dx += (deltaX / deltaLength) * self.attractionForce(deltaLength)
                edge.to.dy += (deltaY / deltaLength) * self.attractionForce(deltaLength)
            }
            
            // move the nodes
            
            for (_,node) in self.nodes {
//                                println("\(node.name) at (\(node.x),\(node.y))")
//                println("\(node.name) delta (\(node.dx),\(node.dy))")

                node.x += (node.dx / self.vectorLength(node.dx, y: node.dy)) * min(abs(node.dx), temperature)
                node.y += (node.dy / self.vectorLength(node.dx, y: node.dy)) * min(abs(node.dy), temperature)
                node.x = min(self.W, max(0, node.x))
                node.y = min(self.H, max(0, node.y))
//                println("\(node.name) at (\(node.x),\(node.y))")
                if node.rank > 0.1 {
                    node.y = rankStep * (node.rank - 1)
//                    let midY = rankStep * (node.rank - 1)
//                    node.y = min(midY + 0.3 * rankStep, max( midY - 0.3 * rankStep, node.y))
                }
            }
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Notification.Name(rawValue: "UpdatePrimGraph"), object: nil)
            }
            
            }
            
        }
    }
    
    func findClosest(_ x: Double, y: Double) -> Node? {
        var closest: Node?
        var closestDistance: Double = 1E20
        for (_,node) in nodes {
            let distance = pow(node.x - x, 2) + pow(node.y - y, 2)
            if distance < closestDistance {
                closest = node
                closestDistance = distance
            }
        }
        return closest
    }
    
    func makeVisibleClosestNodeName(_ x: Double, y: Double)  {
        let closest = findClosest(x, y: y)
        if closest != nil {
            closest!.labelVisible = !closest!.labelVisible
        }
    }
    
    
    func setUpGraph(_ model: Model) {
        nodes = [:]
        edges = []
        constantC = 0.3
        for (_,chunk) in model.dm.chunks {
            if let type = chunk.slotvals["isa"] {
                if type.description == "operator" {
                    var conditionList = chunk.slotvals["condition"]!.description.components(separatedBy: ";")
                    var currentName = ""
                    var currentNode: Node? = nil
                    while !conditionList.isEmpty {
                        let lastItem = conditionList.removeLast()
                        currentName = currentName == "" ? lastItem : lastItem + ";" + currentName
                        if let node = nodes[currentName] {
                            currentNode = node
                            if !chunk.definedIn.isEmpty && (currentNode!.definedByTask! != chunk.definedIn[0] || chunk.definedIn.count > 1) {
                                currentNode!.halo = true
                            }
                        } else {
                            let newNode = Node(name: currentName)
                            newNode.shortName = lastItem
                            newNode.definedByTask = chunk.definedIn.isEmpty ? -3 : chunk.definedIn[0]
                            if (chunk.definedIn.count > 1) {
                                newNode.halo = true
                            }
                            nodes[currentName] = newNode
                            if currentNode != nil {
                                let newEdge = Edge(from: newNode, to: currentNode!)
                                edges.append(newEdge)
                            }
                            currentNode = newNode
                        }
                    }
                    let operatorNode = Node(name: chunk.name)
                    operatorNode.taskNumber = chunk.definedIn.isEmpty ? -3 : chunk.definedIn[0]
                    if chunk.definedIn.count > 1 {
                        operatorNode.halo = true
                    }
                    nodes[chunk.name] = operatorNode
                    for task in chunk.definedIn {
                        let taskName = model.tasks[task].name
                        var taskNode: Node
                        if nodes[taskName] == nil {
                            taskNode = Node(name: taskName)
                            taskNode.taskNumber = task
                            nodes[taskName] = taskNode
                            taskNode.taskNode = true
                        } else {
                            taskNode = nodes[taskName]!
                        }
                        let taskEdge = Edge(from: taskNode, to: operatorNode)
                        edges.append(taskEdge)
                    }
                    let operatorEdge = Edge(from: operatorNode, to: currentNode!)
                    edges.append(operatorEdge)
                    var actionList = chunk.slotvals["action"]!.description.components(separatedBy: ";")
                    currentName = ""
                    currentNode = nil
                    while !actionList.isEmpty {
                        let lastItem = actionList.removeLast()
                        currentName = currentName == "" ? lastItem : lastItem + ";" + currentName
                        if let node = nodes[currentName] {
                            currentNode = node
                            if !chunk.definedIn.isEmpty && (currentNode!.definedByTask! != chunk.definedIn[0] || chunk.definedIn.count > 1) {
                                currentNode!.halo = true
                            }
                        } else {
                            let newNode = Node(name: currentName)
                            newNode.shortName = lastItem
                            newNode.definedByTask = chunk.definedIn.isEmpty ? -3 : chunk.definedIn[0]
                            newNode.taskNumber = -1
                            if (chunk.definedIn.count > 1) {
                                newNode.halo = true
                            }
                            nodes[currentName] = newNode
                            if currentNode != nil {
                                let newEdge = Edge(from: newNode, to: currentNode!)
                                edges.append(newEdge)
                            }
                            currentNode = newNode
                        }
                    }
                    let operatorActionEdge = Edge(from: operatorNode, to: currentNode!)
                    edges.append(operatorActionEdge)
                   
                }
            }
        }
        keys = Array(nodes.keys)
        nodeToIndex = [:]
        for i in 0..<keys.count {
            nodeToIndex[keys[i]] = i
        }
    }
    
    func setUpLearnGraph(_ model: Model) {
        nodes = [:]
        edges = []
        constantC = 1.0
        for (_,prod) in model.procedural.productions {
            if prod.u > model.procedural.primU {
                let node = Node(name: prod.fullName)
                node.shortName = prod.name
                node.rank = Double(prod.conditions.count + prod.actions.count - 1)
                node.taskNumber = prod.taskID
                nodes[node.name] = node
            }
        }
        for (_,prod) in model.procedural.productions {
            if nodes[prod.fullName] != nil {
                let startNode = nodes[prod.fullName]!
                let destNode1 = prod.parent1 == nil ? nil : nodes[prod.parent1!.fullName]
                let destNode2 = prod.parent2 == nil ? nil : nodes[prod.parent2!.fullName]
                if destNode1 != nil {
                    let edge = Edge(from: startNode, to: destNode1!)
                    edges.append(edge)
                }
                if destNode2 != nil {
                    let edge = Edge(from: startNode, to: destNode2!)
                    edges.append(edge)
                }
            }
        }
        keys = Array(nodes.keys)
        nodeToIndex = [:]
        for i in 0..<keys.count {
            nodeToIndex[keys[i]] = i
        }
    }
    
    func setUpDMGraph(_ model: Model) {
        nodes = [:]
        edges = []
        constantC = 1.0
        for (_,chunk) in model.dm.chunks {
            if chunk.type == "fact" {
                let node = Node(name: chunk.name)
                node.shortName = node.name
                nodes[node.name] = node
            }
        }
        for (_,chunk) in model.dm.chunks {
            if chunk.type == "fact" {
                for (_,value) in chunk.slotvals {
                    if let chunk2 = value.chunk() {
                        if chunk2.type == "fact" && chunk2.name != chunk.name {
                        let edge = Edge(from: nodes[chunk.name]!, to: nodes[chunk2.name]!)
                        edges.append(edge)
                        }
                    }
                }
            }
        }
        keys = Array(nodes.keys)
        nodeToIndex = [:]
        for i in 0..<keys.count {
            nodeToIndex[keys[i]] = i
        }
    }
    
}
