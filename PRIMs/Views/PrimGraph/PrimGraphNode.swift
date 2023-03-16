//
//  PrimGraphNode.swift
//  PRIMs
//
//  Created by Niels Taatgen on 3/15/23.
//

import SwiftUI

struct PrimGraphNode: InsettableShape {
    
//    @ObservedObject var model: PRIMsViewModel
    var node: ViewNode
    var insetAmount: CGFloat = 0
    let vertexSize: CGFloat = 6

    func path(in rect: CGRect) -> Path {
        let x = CGFloat(node.x)/300 * rect.width
        let y = CGFloat(node.y)/300 * rect.height
        var path = Path()
        if node.taskNode {
            let sin18 = CGFloat(sin(Double.pi/10) * Double(vertexSize))
            let cos18 = CGFloat(cos(Double.pi/10) * Double(vertexSize))
            let sin54 = CGFloat(sin(3 * Double.pi/10) * Double(vertexSize))
            let cos54 = CGFloat(cos(3 * Double.pi/10) * Double(vertexSize))
            path.move(to: CGPoint(x: x, y: y + vertexSize))
            path.addLine(to: CGPoint(x: x + cos54/2, y: y + sin54/2))
            path.addLine(to: CGPoint(x: x + cos18, y: y + sin18))
            path.addLine(to: CGPoint(x: x + cos18/2, y: y - sin18/2))
            path.addLine(to: CGPoint(x: x + cos54, y: y - sin54))
            path.addLine(to: CGPoint(x: x , y: y - vertexSize/2))
            path.addLine(to: CGPoint(x: x - cos54, y: y - sin54))
            path.addLine(to: CGPoint(x: x - cos18/2, y: y - sin18/2))
            path.addLine(to: CGPoint(x: x - cos18, y: y + sin18))
            path.addLine(to: CGPoint(x: x - cos54/2, y: y + sin54/2))
            path.addLine(to: CGPoint(x: x, y: y + vertexSize))
        } else if node.skillNode {
            let sin18 = CGFloat(sin(Double.pi/10) * Double(vertexSize))
            let cos18 = CGFloat(cos(Double.pi/10) * Double(vertexSize))
            let sin54 = CGFloat(sin(3 * Double.pi/10) * Double(vertexSize))
            let cos54 = CGFloat(cos(3 * Double.pi/10) * Double(vertexSize))
            
            path.move(to: CGPoint(x: x, y: y - vertexSize))
            path.addLine(to: CGPoint(x: x + cos18, y: y - sin18))
            path.addLine(to: CGPoint(x: x + cos54, y: y + sin54))
            path.addLine(to: CGPoint(x: x - cos54, y: y + sin54))
            path.addLine(to: CGPoint(x: x - cos18, y: y - sin18))
            path.addLine(to: CGPoint(x: x, y: y - vertexSize))
        } else {
            path.addEllipse(in: CGRect(x: x - vertexSize, y: y - vertexSize, width: vertexSize * 2, height: vertexSize * 2))
        }
        return path
    }
    func inset(by amount: CGFloat) -> some InsettableShape {
        var arc = self
        arc.insetAmount += amount
        return arc
    }
    

}
