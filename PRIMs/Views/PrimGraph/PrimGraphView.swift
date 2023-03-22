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
                HStack {
                    Picker("Graph Type", selection: $selectedItem) {
                        Text("Task-Skill-Operator Level").tag(1)
                        Text("Skill-Operator-PRIMs Level").tag(2)
                    }
                    .onChange(of: selectedItem, perform: { tag in model.changeLevel(level: tag)} )
                    Button("Refresh"){
                        model.primViewCalculateGraph()
                    }
                }
                GeometryReader { geometry in
                    ZStack {
                        ForEach(model.graphData!.edges) { edge in
                            PrimGraphEdge(edge: edge)
                                .stroke()
                                .foregroundColor(edge.learned ? Color.red : Color.black)
                        }
                        ForEach(model.graphData!.nodes) { node in
                            PrimGraphNode(node: node, geometry: geometry)
                        }
                        
                    }
                }
                
            }
        }
    }
}


