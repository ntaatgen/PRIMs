//
//  PrimGraphView.swift
//  PRIMs
//
//  Created by Niels Taatgen on 3/15/23.
//

import SwiftUI

struct PrimGraphView: View {
    @ObservedObject var model: PRIMsViewModel
    let vertexSize: CGFloat = 6
    @State var selectedItem = 2
    var body: some View {
        if model.graphData != nil {
            VStack {
                Picker("Graph Type", selection: $selectedItem) {
                    Text("Task-Skill-Operator Level").tag(1)
                    Text("Skill-Operator-PRIMs Level").tag(2)
                }
                .onChange(of: selectedItem, perform: { tag in model.changeLevel(level: tag)} )
                
                GeometryReader { geometry in
                    ZStack {
                        ForEach(model.graphData!.edges) { edge in
                            PrimGraphEdge(edge: edge)
                                .stroke()
                        }
                        
                        ForEach(model.graphData!.nodes) { node in
                            if node.halo {
                                PrimGraphHalo(node: node)
                                    .foregroundColor(Color.yellow)
                            }
                            numberToColor(node.taskNumber)
                                .clipShape(PrimGraphNode(node: node))
                            PrimGraphNode(node: node)
                                .strokeBorder(Color.black,lineWidth:node.taskNode == false &&  node.skillNode == false ? 1 : 3)
                            Text(node.name)
                                .font(node.taskNode == false &&  node.skillNode == false ? .caption2 : .title)
                                .position(x:CGFloat(node.x)/300 * geometry.size.width , y: CGFloat(node.y)/300 * geometry.size.height + 2 * vertexSize)
                        }
                        
                    }
                }
                
            }
        }
    }
}

