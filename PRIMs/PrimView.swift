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
    func primViewNumbeOfEdges(sender: PrimView) -> Int
    func primViewEdgeVertices(sender: PrimView, index: Int) -> (Int,Int)
}

class PrimView: NSView {

    var vertexSize: CGFloat = 6
    var lineWidth: CGFloat = 2
    var pathLineWidth: CGFloat = 1
    
    weak var dataSource: PrimViewDataSource!
    
    func drawVertex(x: CGFloat, y: CGFloat, fillColor: NSColor) {
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
//        dataSource.primViewCalculateGraph(self)
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
            drawVertex(CGFloat(x), y: CGFloat(y), fillColor: dataSource.primViewVertexColor(self, index: i))
        }
        
    }
    
}
