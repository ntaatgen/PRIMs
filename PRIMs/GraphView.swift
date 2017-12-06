//
//  GraphView.swift
//  PRIMs
//
//  Created by Niels Taatgen on 4/26/15.
//  Copyright (c) 2015 Niels Taatgen. All rights reserved.
//

import Cocoa

protocol GraphViewDataSource: class {
    func graphXMin(_ sender: GraphView) -> Double?
    func graphXMax(_ sender: GraphView) -> Double?
    func graphYMin(_ sender: GraphView) -> Double?
    func graphYMax(_ sender: GraphView) -> Double?
    func graphNumberOfGraphs(_ sender: GraphView) -> Int
    func graphPointsForGraph(_ sender: GraphView, graph: Int) -> [(Double,Double)]
    func graphColorOfGraph(_ sender: GraphView, graph: Int) -> NSColor?
    func graphTitle(_ sender: GraphView) -> String
}

class GraphView: NSView {
    var lineWidth: CGFloat = 3 { didSet { setNeedsDisplay(self.frame) }}
    var orgX: CGFloat {
        get {
            return bounds.width * 0.1
        }
    }
    var orgY: CGFloat {
        get {
            return bounds.height * 0.1
        }
    }
    
    weak var dataSource: GraphViewDataSource?

    func drawCurve(_ i: Int) {
        let minX = dataSource!.graphXMin(self)!
        let minY = dataSource!.graphYMin(self)!
        let maxX = dataSource!.graphXMax(self)!
        let maxY = dataSource!.graphYMax(self)!
        let path = NSBezierPath()
        var first = true
        for (x,y) in dataSource!.graphPointsForGraph(self, graph: i) {
            let xr = CGFloat((x - minX)/(maxX - minX))
            let yr = CGFloat((y - minY)/(maxY - minY))
            let xp = orgX + xr * (bounds.width * 0.8)
            let yp = orgY + yr * (bounds.height * 0.8)
//            println("x = \(xp) y = \(yp)")
            if first {
                path.move(to: NSPoint(x: xp, y: yp))
                first = false
            } else {
                path.line(to: NSPoint(x: xp, y: yp))
            }
        }
        dataSource!.graphColorOfGraph(self, graph: i)!.set()
        path.lineWidth = lineWidth
        path.stroke()
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let path = NSBezierPath()
        path.move(to: NSPoint(x: orgX,y: orgY))
        path.line(to: NSPoint(x: orgX,y: bounds.height))
        path.move(to: NSPoint(x: orgX,y: orgY))
        path.line(to: NSPoint(x: bounds.width, y: orgY))
        // put the maximum Y value on the Y axis
        var s =  NSMutableAttributedString(string: String(format:"%.1f", dataSource!.graphYMax(self)!))
        s.addAttribute(NSAttributedStringKey.font, value: NSFont.userFont(ofSize: 12.0)!, range: NSMakeRange(0, s.length))
        s.draw(in: NSMakeRect(5, 0.9 * bounds.height , 50, 20))
        // put the minimum Y value on the Y axis
        s =  NSMutableAttributedString(string: String(format:"%.1f", dataSource!.graphYMin(self)!))
        s.addAttribute(NSAttributedStringKey.font, value: NSFont.userFont(ofSize: 12.0)!, range: NSMakeRange(0, s.length))
        s.draw(in: NSMakeRect(5, 0.1 * bounds.height + 5 , 50, 20))
        // put the maximum X value on the X axis
        s =  NSMutableAttributedString(string: String(format:"%.1f", dataSource!.graphXMax(self)!))
        s.addAttribute(NSAttributedStringKey.font, value: NSFont.userFont(ofSize: 12.0)!, range: NSMakeRange(0, s.length))
        s.draw(in: NSMakeRect(0.9 * bounds.width, 5 , 50, 20))
        // put the minumum X value on the X axis
        s =  NSMutableAttributedString(string: String(format:"%.1f", dataSource!.graphXMin(self)!))
        s.addAttribute(NSAttributedStringKey.font, value: NSFont.userFont(ofSize: 12.0)!, range: NSMakeRange(0, s.length))
        s.draw(in: NSMakeRect(0.1 * bounds.width + 5, 5 , 50, 20))
        // put a tile above the graph
        s = NSMutableAttributedString(string: dataSource!.graphTitle(self))
        s.addAttribute(NSAttributedStringKey.font, value: NSFont.userFont(ofSize: 12.0)!, range: NSMakeRange(0, s.length))
        s.setAlignment(NSTextAlignment.center, range: NSMakeRange(0, s.length))
        s.draw(in: NSMakeRect(0.2 * bounds.width, 0.90 * bounds.height, 0.7 * bounds.width, 20))
        path.lineWidth = lineWidth
        NSColor.black.set()
        path.stroke()
        for i in 0..<dataSource!.graphNumberOfGraphs(self) {
            drawCurve(i)
        }
        
    }
    
}
