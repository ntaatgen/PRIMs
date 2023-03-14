//
//  DMView.swift
//  ACT-R-SU
//
//  Created by Niels Taatgen on 28/12/22.
//

import SwiftUI

/// Show the contents of declarative memory. The list shows the chunk names with their activation (ChunkView)
/// If you click on a link, you get the detailed view (ChunkDetailView, in a separate file)
struct DMView: View {
    @ObservedObject var model: PRIMsViewModel
    
    var body: some View {
        VStack {
            Text("Declarative Memory")
            NavigationView {
                List(model.dmContent) {
                    chunk in
                    NavigationLink {
                        HStack {
                            VStack {
                                ChunkDetailView(chunk: chunk)
                                    .padding()
                                Spacer()
                            }
                            Spacer()
                        }
                        .frame(maxWidth: .infinity,maxHeight: .infinity)
                        .background(Color.white)
                    } label: {
                        ChunkView(chunk: chunk)
                    }
                }
                .listStyle(.bordered(alternatesRowBackgrounds: true))
                .navigationTitle("DM Contents")
            }
        }
        
    }
}

struct ChunkView: View {
    var chunk: PublicChunk
    var body: some View {
        HStack {
            Text(chunk.name)
            Text(" \(chunk.activation)").font(.caption2)
            Spacer()
        }
    }
}

//struct DMView_Previews: PreviewProvider {
//    static var previews: some View {
//        DMView()
//    }
//}
