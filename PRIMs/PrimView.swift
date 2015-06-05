//
//  PrimView.swift
//  PRIMs
//
//  Created by Niels Taatgen on 5/13/15.
//  Copyright (c) 2015 Niels Taatgen. All rights reserved.
//

import Cocoa

protocol PrimViewDataSource: class {
    func primViewCalculateGraph(sender: PrimView)
    func primViewNumberOfVertices(sender: PrimView) -> Int
    func primViewVertexCoordinates(sender: PrimView, index: Int) -> (Double,Double)
    func primViewVertexLabel(sender: PrimView, index: Int) -> String
    func primViewVertexColor(sender: PrimView, index: Int) -> NSColor
    func primViewVertexBroad(sender: PrimView, index: Int) -> Bool
    func primViewNumbeOfEdges(sender: PrimView) -> Int
    func primViewEdgeVertices(sender: PrimView, index: Int) -> (Int,Int)
    func primViewRescale(sender: PrimView, newW: Double, newH: Double)
    func primViewVisibleLabel(sender: PrimView, index: Int) -> String?
}

class PrimView: NSView {

    var vertexSize: CGFloat = 6
    var lineWidth: CGFloat = 2
    var pathLineWidth: CGFloat = 1
    var broadLineWidth: CGFloat = 8
    weak var dataSource: PrimViewDataSource!
    
    func drawVertex(x: CGFloat, y: CGFloat, fillColor: NSColor, lineWidth: CGFloat) {
        let rect = NSRect(x: x - vertexSize, y: y - vertexSize, width: vertexSize * 2, height: vertexSize * 2)
        let path = NSBezierPath(ovalInRect: rect)
        path.lineWidth = lineWidth
        NSColor.blackColor().set()
        path.stroke()
        fillColor.setFill()
        path.fill()
    }
    
    func drawEdge(start: NSPoint, end: NSPoint) {
        let path = NSBezierPath()
        path.moveToPoint(start)
        path.lineToPoint(end)
        path.lineWidth = pathLineWidth
        NSColor.blackColor().set()
        path.stroke()
    }
    
    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)
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
            drawVertex(CGFloat(x), y: CGFloat(y), fillColor: dataSource.primViewVertexColor(self, index: i),lineWidth: lw)
        }
        for i in 0..<numNodes {
            if let nodeLabel = dataSource.primViewVisibleLabel(self, index: i) {
                let (x,y) = dataSource.primViewVertexCoordinates(self, index: i)
                var s = NSMutableAttributedString(string: nodeLabel)
                s.addAttribute(NSFontAttributeName, value: NSFont.userFontOfSize(10.0)!, range: NSMakeRange(0, s.length))
                s.drawAtPoint(NSPoint(x: x + Double(vertexSize), y: y + Double(vertexSize)))
//                s.drawInRect(NSRect(x: x, y: y, width: 100.0, height: 40.0))

            }
        }
        
    }
    
}
