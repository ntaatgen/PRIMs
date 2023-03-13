//
//  PrimsViewController.swift
//  PRIMs
//
//  Created by Niels Taatgen on 3/10/23.
//

import SwiftUI
import Cocoa

struct PrimsViewController<PrimView: View>: NSViewControllerRepresentable {
    func makeNSViewController(context: Context) -> NSViewController {
        let primViewController = NSViewController()
    }
    
    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {
        <#code#>
    }
    
    var primGraphData: FruchtermanReingold?
    
    @IBOutlet weak var primGraph: PrimView! {
        didSet { primGraph.dataSource = self }
    }
    
    @IBAction func redisplayPrimGraph(_ sender: NSButton) {
        primViewCalculateGraph(primGraph)
        primGraph.needsDisplay = true
    }
    
    @IBOutlet weak var popUpMenu: NSPopUpButton!
    
    @IBAction func popUpMenuSelected(_ sender: NSPopUpButton) {
        primViewCalculateGraph(primGraph)
        primGraph.needsDisplay = true
    }
    
    let border = 10.0

    func primViewCalculateGraph(_ sender: PrimView) {
        primGraphData = FruchtermanReingold(W: Double(sender.bounds.width) - 3 * border, H: Double(sender.bounds.height) - 3 * border)
        let graphType = popUpMenu.selectedItem!.title
        switch graphType {
            case "Tasks":
                primGraphData!.constantC = 1.0
                primGraphData!.setUpGraph(model, level: 1)
            case "PRIMs":
                primGraphData!.constantC = 0.3
                primGraphData!.setUpGraph(model, level: 2)
            case "Productions": primGraphData!.setUpLearnGraph(model)
            case "Declarative": primGraphData!.setUpDMGraph(model)
        default: break // Shouldn't happen
        }
        primGraphData!.calculate(randomInit: true)
    }
    
    @IBAction func primViewReCalculateGraph(_ sender: NSButtonCell) {
        guard primGraphData != nil else { return }
        primGraphData!.calculate(randomInit: false)
        primGraph.needsDisplay = true
    }
    
    
    func primViewNumberOfVertices(_ sender: PrimView) -> Int {
        if primGraphData == nil {
            return 0
        } else {
            return primGraphData!.nodes.count
        }
    }

    func primViewNumbeOfEdges(_ sender: PrimView) -> Int {
        if primGraphData == nil {
            return 0
        } else {
            return primGraphData!.edges.count
        }
    }

    func primViewVertexCoordinates(_ sender: PrimView, index: Int) -> (Double, Double) {
        if primGraphData == nil {
            return (0,0)
        } else {
            let key = primGraphData!.keys[index]
            return (primGraphData!.nodes[key]!.x + border, primGraphData!.nodes[key]!.y + border)
        }
    }
    
    func primViewEdgeVertices(_ sender: PrimView, index: Int) -> (Int, Int) {
        if primGraphData == nil {
            return (0,0)
        } else {
            let vertex1 = primGraphData!.edges[index].from
            let vertex2 = primGraphData!.edges[index].to
            return (primGraphData!.nodeToIndex[vertex1.name]! , primGraphData!.nodeToIndex[vertex2.name]!)
        }
    }
    
    func primViewVertexColor(_ sender: PrimView, index: Int) -> NSColor {
        if primGraphData == nil {
            return NSColor.white
        } else {
            let key = primGraphData!.keys[index]
            let taskNumber = primGraphData!.nodes[key]!.taskNumber
            return numberToColor(taskNumber)
        }
    }
    
    func primViewVertexLabel(_ sender: PrimView, index: Int) -> String {
        if primGraphData == nil {
            return ""
        } else {
            let key = primGraphData!.keys[index]
            return primGraphData!.nodes[key]!.name
        }
    }
    
    func primViewRescale(_ sender: PrimView, newW: Double, newH: Double) {
        if primGraphData != nil {
            primGraphData!.rescale(newW - 3 * border, newH: newH - 3 * border)
        }
    }

    func primViewVertexBroad(_ sender: PrimView, index: Int) -> Bool {
        if primGraphData != nil {
            let key = primGraphData!.keys[index]
            return primGraphData!.nodes[key]!.taskNode
        }
        return false
    }
    
    func primViewVertexHalo(_ sender: PrimView, index: Int) -> Bool {
        if primGraphData != nil {
            let key = primGraphData!.keys[index]
            return primGraphData!.nodes[key]!.halo
        }
        return false
    }
    
    func primViewEdgeColor(_ sender: PrimView, index: Int) -> NSColor {
        guard primGraphData != nil else { return NSColor.black }
        return primGraphData!.edges[index].learned ? NSColor.red : NSColor.black
    }
    
    func primViewVertextIsRectangle(_ sender: PrimView, index: Int) -> Bool {
        guard primGraphData != nil else { return false }
        let key = primGraphData!.keys[index]
        return primGraphData!.nodes[key]!.mainTaskNode
    }
    
    @IBOutlet weak var allLabelsButton: NSButton!
    
    @IBAction func allLabelsButtonPushed(_ sender: NSButton) {
         primGraph.needsDisplay = true
    }
    
    func primViewVisibleLabel(_ sender: PrimView, index: Int) -> String? {
        if primGraphData != nil {
            let key = primGraphData!.keys[index]
            if primGraphData!.nodes[key]!.labelVisible || allLabelsButton.state == NSControl.StateValue.on  {
                return primGraphData!.nodes[key]!.shortName
            }
        }
        return nil
    }
    
    @objc func updatePrimGraph() {
        primGraph.needsDisplay = true
    }
    
    @IBOutlet weak var primViewView: PrimView!
    
    
    @IBAction func clickInPrimView(_ sender: NSClickGestureRecognizer) {
        let location = sender.location(in: primViewView)
        if primGraphData == nil { return }
        primGraphData!.makeVisibleClosestNodeName(Double(location.x) - border,y: Double(location.y) - border)
        primGraph.needsDisplay = true
        
    }
    
    var nodeToBeMoved: Node?
    
    @IBAction func dragInPrimView(_ sender: NSPanGestureRecognizer) {
        let location: NSPoint = sender.location(in: primViewView)
        switch sender.state {
        case .began:
            nodeToBeMoved = primGraphData!.findClosest(Double(location.x) - border, y: Double(location.y) - border)
            if nodeToBeMoved != nil {
                nodeToBeMoved!.fixed = true
            }
        case .ended:
            nodeToBeMoved = nil
        default: break
        }
        if nodeToBeMoved != nil {
            nodeToBeMoved!.x = Double(location.x) - border
            nodeToBeMoved!.y = Double(location.y) - border
            primGraph.needsDisplay = true
        }
        
    }
    
    
    typealias NSViewControllerType = NSViewController
    
    
    
    
}
