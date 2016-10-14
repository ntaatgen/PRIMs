//
//  PrimView.swift
//  PRIMs
//
//  Created by Niels Taatgen on 5/13/15.
//  Copyright (c) 2015 Niels Taatgen. All rights reserved.
//

import Cocoa

protocol PrimViewDataSource: class {
    func primViewCalculateGraph(_ sender: PrimView)
    func primViewNumberOfVertices(_ sender: PrimView) -> Int
    func primViewVertexCoordinates(_ sender: PrimView, index: Int) -> (Double,Double)
    func primViewVertexLabel(_ sender: PrimView, index: Int) -> String
    func primViewVertexColor(_ sender: PrimView, index: Int) -> NSColor
    func primViewVertexBroad(_ sender: PrimView, index: Int) -> Bool
    func primViewNumbeOfEdges(_ sender: PrimView) -> Int
    func primViewEdgeVertices(_ sender: PrimView, index: Int) -> (Int,Int)
    func primViewRescale(_ sender: PrimView, newW: Double, newH: Double)
    func primViewVisibleLabel(_ sender: PrimView, index: Int) -> String?
    func primViewVertexHalo(_ sender: PrimView, index: Int) -> Bool
}

class PrimView: NSView {

    var vertexSize: CGFloat = 6
    var lineWidth: CGFloat = 2
    var pathLineWidth: CGFloat = 1
    var broadLineWidth: CGFloat = 8
    var haloSize: CGFloat = 10
    var arrowSize: CGFloat = 6
    weak var dataSource: PrimViewDataSource!
    
    func drawVertex(_ x: CGFloat, y: CGFloat, fillColor: NSColor, lineWidth: CGFloat, halo: Bool) {
        if halo {
            let rect = NSRect(x: x - haloSize, y: y - haloSize, width: haloSize * 2, height: haloSize * 2)
            let path = NSBezierPath(ovalIn: rect)
            path.lineWidth = 0
            NSColor.yellow.setFill()
            path.fill()
        }
        let rect = NSRect(x: x - vertexSize, y: y - vertexSize, width: vertexSize * 2, height: vertexSize * 2)
        let path = NSBezierPath(ovalIn: rect)
        path.lineWidth = lineWidth
        NSColor.black.set()
        path.stroke()
        fillColor.setFill()
        path.fill()
    }
    
    func drawEdge(_ start: NSPoint, end: NSPoint) {
        let π = CGFloat(M_PI)
        var angle: CGFloat
        if start.x != end.x {
            angle = atan((end.y - start.y) / (end.x - start.x))
        } else {
            angle = start.y > end.y ? -π/2 : π/2
        }
        if start.x > end.x {
            angle += π
        }
        let intersect = NSPoint(x: end.x - (vertexSize + lineWidth) * cos(angle), y: end.y - (vertexSize + lineWidth) * sin(angle))
        let arrowtip1 = NSPoint(x: intersect.x + arrowSize * cos(angle - 0.75 * π), y: intersect.y + arrowSize * sin(angle - 0.75 * π))
        let arrowtip2 = NSPoint(x: intersect.x + arrowSize * cos(angle + 0.75 * π), y: intersect.y + arrowSize * sin(angle + 0.75 * π))
        
        let path = NSBezierPath()
        path.move(to: start)
        path.line(to: intersect)
        path.line(to: arrowtip1)
        path.move(to: intersect)
        path.line(to: arrowtip2)
        path.lineWidth = pathLineWidth
        NSColor.black.set()
        path.stroke()
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        self.autoresizesSubviews = true
//        dataSource.primViewCalculateGraph(self)
        dataSource.primViewRescale(self, newW: Double(self.bounds.width) , newH: Double(self.bounds.height))
        let numEdges = dataSource.primViewNumbeOfEdges(self)
        for i in 0..<numEdges {
            let (source,destination) = dataSource.primViewEdgeVertices(self, index: i)
            let (sourceX,sourceY) = dataSource.primViewVertexCoordinates(self, index: source)
            let (destinationX,destinationY) = dataSource.primViewVertexCoordinates(self, index: destination)
            let startPoint = NSPoint(x: sourceX, y: sourceY)
            let endPoint = NSPoint(x: destinationX, y: destinationY)
            drawEdge(startPoint, end: endPoint)
        }
        let numNodes = dataSource.primViewNumberOfVertices(self)
        for i in 0..<numNodes {
            let (x,y) = dataSource.primViewVertexCoordinates(self, index: i)
            let lw = dataSource.primViewVertexBroad(self, index: i) ? broadLineWidth : lineWidth
            drawVertex(CGFloat(x), y: CGFloat(y), fillColor: dataSource.primViewVertexColor(self, index: i),lineWidth: lw, halo: dataSource.primViewVertexHalo(self, index: i))
        }
        for i in 0..<numNodes {
            if let nodeLabel = dataSource.primViewVisibleLabel(self, index: i) {
                let (x,y) = dataSource.primViewVertexCoordinates(self, index: i)
                let s = NSMutableAttributedString(string: nodeLabel)
                s.addAttribute(NSFontAttributeName, value: NSFont.userFont(ofSize: 10.0)!, range: NSMakeRange(0, s.length))
                s.draw(at: NSPoint(x: x + Double(vertexSize), y: y + Double(vertexSize)))
//                s.drawInRect(NSRect(x: x, y: y, width: 100.0, height: 40.0))

            }
        }
        
    }
    
}
