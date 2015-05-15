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
    init(name: String) {
        self.name = name
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
    let W: Double
    let H: Double
    let iterations = 100
    let constantC = 0.3
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
    
    func attractionForce(x: Double) -> Double {
        return pow(x,2)/k
    }
    
    func repulsionForce(z: Double) -> Double {
        return pow(k,2) / z
    }

    func vectorLength(x: Double, y: Double) -> Double {
        return sqrt(pow(x,2)+pow(y,2))
    }
    
    func calculate() {
        for (_,node) in nodes {
            node.x = Double(Int(arc4random_uniform(UInt32(W))))
            node.y = Double(Int(arc4random_uniform(UInt32(H))))
            
        }
        for i in 0..<iterations {
            let temperature = 0.1 * max(W,H) * Double(iterations - i)/Double(iterations)
            // Calculate repulsive forces
            for (_,node) in nodes {
                node.dx = 0
                node.dy = 0
                for (_,node2) in nodes {
                    if node !== node2 {
                        let deltaX = node.x - node2.x
                        let deltaY = node.y - node2.y
                        let deltaLength = vectorLength(deltaX, y: deltaY)
                        node.dx += (deltaX / deltaLength) * repulsionForce(deltaLength)
                        node.dy += (deltaY / deltaLength) * repulsionForce(deltaLength)
                    }
                }
                // repulsion of walls
                node.dx += repulsionForce(node.x)
                node.dx -= repulsionForce(W - node.x)
                node.dy += repulsionForce(node.y)
                node.dy -= repulsionForce(H - node.y)
                
            }
            // calculate attractive forces
            
            for edge in edges {
                let deltaX = edge.from.x - edge.to.x
                let deltaY = edge.from.y - edge.to.y
                let deltaLength = vectorLength(deltaX, y: deltaY)
                edge.from.dx -= (deltaX / deltaLength) * attractionForce(deltaLength)
                edge.from.dy -= (deltaY / deltaLength) * attractionForce(deltaLength)
                edge.to.dx += (deltaX / deltaLength) * attractionForce(deltaLength)
                edge.to.dy += (deltaY / deltaLength) * attractionForce(deltaLength)
            }
            
            // move the nodes
            
            for (_,node) in nodes {
//                                println("\(node.name) at (\(node.x),\(node.y))")
//                println("\(node.name) delta (\(node.dx),\(node.dy))")

                node.x += (node.dx / vectorLength(node.dx, y: node.dy)) * min(abs(node.dx), temperature)
                node.y += (node.dy / vectorLength(node.dx, y: node.dy)) * min(abs(node.dy), temperature)
                node.x = min(W, max(0, node.x))
                node.y = min(H, max(0, node.y))
//                println("\(node.name) at (\(node.x),\(node.y))")

            }
            
            
            
        }
    }
    
    func setUpGraph(model: Model) {
        nodes = [:]
        edges = []
        for (_,chunk) in model.dm.chunks {
            if let type = chunk.slotvals["isa"] {
                if type.description == "operator" {
                    var conditionList = chunk.slotvals["condition"]!.description.componentsSeparatedByString(";")
                    var currentName = ""
                    var currentNode: Node? = nil
                    while !conditionList.isEmpty {
                        let lastItem = conditionList.removeLast()
                        currentName = currentName == "" ? lastItem : lastItem + ";" + currentName
                        if let node = nodes[currentName] {
                            currentNode = node
                        } else {
                            let newNode = Node(name: currentName)
                            nodes[currentName] = newNode
                            if currentNode != nil {
                                let newEdge = Edge(from: newNode, to: currentNode!)
                                edges.append(newEdge)
                            }
                            currentNode = newNode
                        }
                    }
                    let operatorNode = Node(name: chunk.name)
                    operatorNode.taskNumber = chunk.definedIn!
                    nodes[chunk.name] = operatorNode
                    let taskName = "\(chunk.definedIn!)"
                    var taskNode: Node
                    if nodes[taskName] == nil {
                        taskNode = Node(name: taskName)
                        taskNode.taskNumber = chunk.definedIn!
                        nodes[taskName] = taskNode
                    } else {
                        taskNode = nodes[taskName]!
                    }
                    let taskEdge = Edge(from: taskNode, to: operatorNode)
                    edges.append(taskEdge)
                    let operatorEdge = Edge(from: operatorNode, to: currentNode!)
                    edges.append(operatorEdge)
                    var actionList = chunk.slotvals["action"]!.description.componentsSeparatedByString(";")
                    currentName = ""
                    currentNode = nil
                    while !actionList.isEmpty {
                        let lastItem = actionList.removeLast()
                        currentName = currentName == "" ? lastItem : lastItem + ";" + currentName
                        if let node = nodes[currentName] {
                            currentNode = node
                        } else {
                            let newNode = Node(name: currentName)
                            newNode.taskNumber = -1
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
    
    
    
}