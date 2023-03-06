//
//  ChunkDetailView.swift
//  ACT-R-SU
//
//  Created by Niels Taatgen on 28/12/22.
//

import SwiftUI

struct ChunkDetailView: View {
    var chunk: PublicChunk
    var body: some View {
        VStack {
            Text(chunk.description)
            Text("Chunk Activation =\n  \(chunk.activation)")
        }
    }
}

//struct ChunkDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        ChunkDetailView()
//    }
//}
