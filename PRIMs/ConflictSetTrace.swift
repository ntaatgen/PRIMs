//
//  ConflictSetTrace.swift
//  PRIMs
//
//  Created by Niels Taatgen on 1/5/18.
//  Copyright © 2018 Niels Taatgen. All rights reserved.
//

import Foundation

class ConflictSetTrace {
    /// Maximum number of items in the table
    let maxTableSize = 30
    
    weak var model: Model!
    
    var chunks: [(Chunk, Double)]  {
        return model.dm.conflictSet.sorted(by: { (item1, item2) -> Bool in
            let (_,u1) = item1
            let (_,u2) = item2
            return u1 > u2
        })}
    
    var chunkTexts: [String : String] = [:]
    
    func spreadingFromBufferDescription(bufferName: String, spreadingParameterValue: Double, chunk: Chunk) -> (String, Int) {
        if spreadingParameterValue == 0 { return ("", 1) }
        var s = ""
        
        var totalSlots: Int = 0
        if  let bufferChunk = model.buffers[bufferName] {
            s += "Spreading from \(bufferName) buffer, spreading parameter = \(spreadingParameterValue.string(fractionDigits: 3))\n"
            for (_,value) in bufferChunk.slotvals {
                if value.chunk() != nil {
                    totalSlots += 1
                }
            }
            for (slot,value) in bufferChunk.slotvals {
                
                switch value {
                case .symbol(let valchunk):
                    let spreading = valchunk.sji(chunk) * spreadingParameterValue / Double(totalSlots)
                    if spreading > 0 {
                        s += "  spreading \(spreading.string(fractionDigits: 3)) from slot \(slot) with value \(valchunk.name), Sji = \(valchunk.sji(chunk).string(fractionDigits: 3))\n"
                    }
                default:
                    break
                }
            }
            
        }
        return (s, totalSlots)
    }
    
    
    func generateChunkTexts() {
        for (chunk,_) in chunks {
            var s = chunk.description + "\n"
            s += "Total Activation = \(chunk.activation().string(fractionDigits: 3))\n"
            s += "Baselevel activation = \(chunk.baseLevelActivation().string(fractionDigits: 3))\n"
            s += "Current noise = \(chunk.noiseValue.string(fractionDigits: 3))\n"
            s += "\nSpreading Activation\n"
            
            var totalSlots = 0
            if model.dm.goalSpreadingByActivation {
                s += "Spreading from the Goal buffer \(model.dm.goalActivation)"
                if let goal=model.buffers["goal"] {
                    for (slot,value) in goal.slotvals {
                        switch value {
                        case .symbol(let valchunk):
                            //                        totalSpreading += valchunk.sji(self) * max(0,valchunk.baseLevelActivation())
                            totalSlots += 1
                            //                        if valchunk.type == "fact" {
                            //                            // spread from slot1
                            //                            if let spreadingChunk = valchunk.slotvals["slot1"]?.chunk() {
                            //                                totalSpreading += spreadingChunk.sji(self) * exp(spreadingChunk.baseLevelActivation()) * model.dm.goalActivation
                            //                            }
                            //                        } else {
                            let spreading = valchunk.sji(chunk) * exp(valchunk.baseLevelActivation()) * model.dm.goalActivation
                            if spreading > 0 {
                                s += "   Spreading \(spreading.string(fractionDigits: 3)) from slot \(slot) with value \(valchunk.name) Wj = \(exp(valchunk.baseLevelActivation()).string(fractionDigits: 3)), Sji = \(valchunk.sji(chunk).string(fractionDigits: 3))\n"
                            }
                        //                        }
                        default:
                            break
                        }
                    }
                }
            } else {
                let result = spreadingFromBufferDescription(bufferName: "goal", spreadingParameterValue: model.dm.goalActivation, chunk: chunk)
                s += result.0
                totalSlots = result.1
            }
            if let goal=model.buffers["goal"] {
                for (slot,value) in goal.slotvals {
                    if let nestedGoal = value.chunk()?.slotvals["slot1"]?.chunk(), nestedGoal.type == "goaltype" {
                        if model.dm.goalSpreadingByActivation {
                            let spreading = nestedGoal.sji(chunk) * exp(value.chunk()!.baseLevelActivation()) * model.dm.goalActivation
                            if spreading > 0 {
                                s += "   Spreading \(spreading.string(fractionDigits: 3)) from slot \(slot) with value \(nestedGoal.name) Wj = \(exp(value.chunk()!.baseLevelActivation()).string(fractionDigits: 3)), Sji = \(nestedGoal.sji(chunk).string(fractionDigits: 3))\n"
                            }
                        } else {
                            let spreading = nestedGoal.sji(chunk) * model.dm.goalActivation / Double(totalSlots)
                            if spreading > 0 {
                                s += "   Spreading \(spreading.string(fractionDigits: 3)) from slot \(slot) with value \(nestedGoal.name),  Sji = \(nestedGoal.sji(chunk).string(fractionDigits: 3))\n"
                            }
                        }
                    }
                }
            }
            s += spreadingFromBufferDescription(bufferName: "input", spreadingParameterValue: model.dm.inputActivation, chunk: chunk).0
            s += spreadingFromBufferDescription(bufferName: "retrievalH", spreadingParameterValue: model.dm.retrievalActivation, chunk: chunk).0
            s += spreadingFromBufferDescription(bufferName: "imaginal", spreadingParameterValue: model.dm.imaginalActivation, chunk: chunk).0
            chunkTexts[chunk.name] = s
        }
    }
    
}
