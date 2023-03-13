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
                        Text(chunk.text)
                    } label: {
                        Text(chunk.name)
                    }
                }
                .listStyle(.bordered(alternatesRowBackgrounds: true))
                .navigationTitle("Conflict Trace")
            }
        }
    }
}

