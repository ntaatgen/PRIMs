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
    let vertexSize: CGFloat = 8

    func path(in rect: CGRect) -> Path {
        var p = Path()
            p.addEllipse(in: CGRect(x: CGFloat(node.x)/300 * rect.width - vertexSize, y: CGFloat(node.y)/300 * rect.height - vertexSize, width: vertexSize * 2, height: vertexSize * 2))
            print("x: \(node.x)  y: \(node.y) x: \(CGFloat(node.x)/300 * rect.width) y: \(CGFloat(node.y)/300 * rect.height)")
        return p
    }
    func inset(by amount: CGFloat) -> some InsettableShape {
        var arc = self
        arc.insetAmount += amount
        return arc
    }
    

}
