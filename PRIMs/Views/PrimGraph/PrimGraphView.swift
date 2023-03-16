//
//  PrimGraphView.swift
//  PRIMs
//
//  Created by Niels Taatgen on 3/15/23.
//

import SwiftUI

struct PrimGraphView: View {
    @ObservedObject var model: PRIMsViewModel
    let vertexSize: CGFloat = 8

    var body: some View {
        if model.graphData != nil {
            GeometryReader { geometry in
                ZStack {
                    ForEach(model.graphData!.edges) { edge in
                        PrimGraphEdge(edge: edge)
                            .stroke()
                    }
                    
                    ForEach(model.graphData!.nodes) { node in
                        numberToColor(node.taskNumber)
                            .clipShape(PrimGraphNode(node: node))
                        PrimGraphNode(node: node)
                            .strokeBorder(Color.black,lineWidth:1)
                        Text(node.name)
                            .font(.caption2)
                            .position(x:CGFloat(node.x)/300 * geometry.size.width , y: CGFloat(node.y)/300 * geometry.size.height + 2 * vertexSize)
                    }
                    
                }
            }
        }
    }
}

