//
//  ConflictTraceView.swift
//  PRIMs
//
//  Created by Niels Taatgen on 3/10/23.
//

import SwiftUI

struct ConflictTraceView: View {
    @ObservedObject var model: PRIMsViewModel

    var body: some View {
        VStack {
            Text("Conflict Trace")
            NavigationView {
                List(model.chunkTexts) {
                    chunk in
                    NavigationLink {
                        VStack {
                            Text(chunk.text)
                                .padding()
                            Spacer()
                        }
                        .background(Color.white)
                        
                    } label: {
                        Text(chunk.name)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        //                            .background(Color(hue: 0.3, saturation: 1, brightness: 1, opacity: 0.5))
                        //                            .background(Color(hue: (chunk.relativeActivation/3), saturation: 1, brightness: 1, opacity: 0.5   ))
                    }
                    
                }
                .listStyle(.bordered(alternatesRowBackgrounds: true))
                .navigationTitle("Conflict Trace")
            }
        }
    }
}

