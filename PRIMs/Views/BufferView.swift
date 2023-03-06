//
//  BufferView.swift
//  PRIMs
//
//  Created by Niels Taatgen on 3/3/23.
//

import SwiftUI

struct BufferView: View {
    @ObservedObject var model: PRIMsViewModel
    var body: some View {
        ScrollView {
            VStack {
                VStack {
                    Text("Operator").font(.bold(.body)())
                    Text(model.operatorString)
                        .multilineTextAlignment(.leading)
                }
                Divider()
                HStack(alignment: .top) {
                    VStack {
                        Text("Input").font(.bold(.body)())
                        Text(model.formerInput)
                            .multilineTextAlignment(.leading)
                    }
                    Divider()
                    VStack {
                        Text("Action").font(.bold(.body)())
                        Text(model.modelAction)
                            .multilineTextAlignment(.leading)
                        }
                    Divider()
                    VStack {
                        Text("New Input").font(.bold(.body)())
                        Text(model.newInput)
                                .multilineTextAlignment(.leading)
                    }
                }
                Divider()
                HStack(alignment: .top) {
                    VStack {
                        Text("Goal").font(.bold(.body)())
                        Text(model.formerGoal)
                            .multilineTextAlignment(.leading)
                        }
                    Divider()
                    VStack {
                        Text("New Goal").font(.bold(.body)())
                        Text(model.newGoal)
                            .multilineTextAlignment(.leading)
                        }
                }
                Divider()
                HStack(alignment: .top) {
                    VStack {
                        Text("Retrieval harvest").font(.bold(.body)())
                        Text(model.formerRetrievalHarvest)
                            .multilineTextAlignment(.leading)
                        }
                    Divider()
                    VStack {
                        Text("Retrieval request").font(.bold(.body)())
                        Text(model.retrievalRequest)
                            .multilineTextAlignment(.leading)
                        }
                    Divider()
                    VStack {
                        Text("New harvest").font(.bold(.body)())
                        Text(model.newRetrievalHarvest)
                            .multilineTextAlignment(.leading)
                        }
                }
                Divider()
                HStack(alignment: .top) {
                    VStack {
                        Text("Imaginal").font(.bold(.body)())
                        Text(model.formerImaginal)
                            .multilineTextAlignment(.leading)
                        }
                    Divider()
                    VStack {
                        Text("New Imaginal").font(.bold(.body)())
                        Text(model.newImaginal)
                            .multilineTextAlignment(.leading)
                        }
                }
                Divider()
            }
            .padding()
            .background(Color.white)
        }
    }
}

struct BufferView_Previews: PreviewProvider {
    static var previews: some View {
        BufferView(model: PRIMsViewModel())
    }
}
