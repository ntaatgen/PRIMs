//
//  PrimGraphNode.swift
//  PRIMs
//
//  Created by Niels Taatgen on 3/15/23.
//

import SwiftUI

struct PrimGraphNode: View {
//    @ObservedObject var model: PRIMsViewModel
    var node: ViewNode
    let vertexSize: CGFloat = 6
    var geometry: GeometryProxy
    var body: some View {
        ZStack {
            PrimGraphNodeShape(node: node)
                .strokeBorder(Color.black, lineWidth: node.skillNode == false && node.taskNode == false ? 1 : 3)
                .background(PrimGraphNodeShape(node: node).foregroundColor(numberToColor(node.taskNumber)))
            Text(node.name)
                .font(node.skillNode == false && node.taskNode == false ? .caption2 : .title2)
                .position(x: CGFloat(node.x)/300 * geometry.size.width,
                          y: CGFloat(node.y)/300 * geometry.size.height + 2 * vertexSize)
        }
        
        
    }
    
    
    
}
