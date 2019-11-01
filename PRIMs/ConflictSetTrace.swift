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
    
    func formatOperator(chunk: Chunk) -> String {
        let operatorName = chunk.name
        var s = "operator \(operatorName) {\n"
        if let condition = chunk.slotvals["condition"] {
            var substitutedCondition = condition.description
            for (slot,value) in chunk.slotvals {
                if slot.hasPrefix("slot") {
                    let replace = "C" + String(slot.dropFirst(4))
                    substitutedCondition = substitutedCondition.replacingOccurrences(of: replace, with: value.description)
                }
            }
            let conditions = substitutedCondition.components(separatedBy: ";")
                for element in conditions {
                s += "    \(element)\n"
            }
            s += "==>\n"
        }
        if let action = chunk.slotvals["action"] {
            var substitutedAction = action.description
            substitutedAction = substitutedAction.replacingOccurrences(of: "AC", with: "###")
            for (slot,value) in chunk.slotvals {
                if slot.hasPrefix("slot") {
                    let replace = "C" + String(slot.dropFirst(4))
                    substitutedAction = substitutedAction.replacingOccurrences(of: replace, with: value.description)
                }
            }
            substitutedAction = substitutedAction.replacingOccurrences(of: "###", with: "AC")

            let actions = substitutedAction.components(separatedBy: ";")
            for element in actions {
                s += "    \(element)\n"
            }
        }
        s += "}\n"
        return s
    }
        

    
    func spreadingFromBufferDescription(bufferName: String, spreadingParameterValue: Double, chunk: Chunk, divideBySlots: Bool) -> (String, Int) {
        if spreadingParameterValue == 0 { return ("", 1) }
        var s = ""
        
        var totalSlots: Int = 0
        if  let bufferChunk = model.buffers[bufferName] {
            s += "Spreading from \(bufferName) buffer, spreading parameter = \(spreadingParameterValue.string(fractionDigits: 3))\n"
            if divideBySlots {
                for (_,value) in bufferChunk.slotvals {
                    if value.chunk() != nil {
                        totalSlots += 1
                    }
                }
            } else {
                totalSlots = 1
            }
            for (slot,value) in bufferChunk.slotvals {
                switch value {
                case .symbol(let valchunk):
                    let spreading = valchunk.sji(chunk, buffer: bufferName, slot: slot) * spreadingParameterValue / Double(totalSlots)
                    if spreading != 0 {
                        s += "  spreading \(spreading.string(fractionDigits: 3)) from slot \(slot) with value \(valchunk.name), Sji = \(valchunk.sji(chunk, buffer: bufferName, slot: slot).string(fractionDigits: 3))\n"
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
            var s = ""
            if chunk.type == "operator" {
                s = formatOperator(chunk: chunk)
            } else {
                s = chunk.description + "\n"
            }
            s += "Total Activation = \(chunk.activation().string(fractionDigits: 3))\n"
            s += "Baselevel activation = \(chunk.baseLevelActivation().string(fractionDigits: 3))\n"
            s += "Current noise = \(chunk.noiseValue.string(fractionDigits: 3))\n"
            s += "\nSpreading Activation\n"
            
//            var totalSlots = 1
            if model.dm.goalSpreadingByActivation {
                s += "Spreading from the Goal buffer \(model.dm.goalActivation)"
                if let goal=model.buffers["goal"] {
                    for (slot,value) in goal.slotvals {
                        switch value {
                        case .symbol(let valchunk):
                            //                        totalSpreading += valchunk.sji(self) * max(0,valchunk.baseLevelActivation())
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
                let result = spreadingFromBufferDescription(bufferName: "goal", spreadingParameterValue: model.dm.goalActivation, chunk: chunk, divideBySlots: false)
                s += result.0
//                totalSlots = result.1
            }
            if let goal=model.buffers["goal"] {
                for (slot,value) in goal.slotvals {
                    if value.chunk() != nil && value.chunk()!.type != "goaltype", let nestedGoal = value.chunk()?.slotvals["slot1"]?.chunk(), nestedGoal.type == "goaltype" {
                        if model.dm.goalSpreadingByActivation {
                            let spreading = nestedGoal.sji(chunk) * exp(value.chunk()!.baseLevelActivation()) * model.dm.goalActivation
                            if spreading > 0 {
                                s += "   Spreading \(spreading.string(fractionDigits: 3)) from slot \(slot) with value \(nestedGoal.name) Wj = \(exp(value.chunk()!.baseLevelActivation()).string(fractionDigits: 3)), Sji = \(nestedGoal.sji(chunk).string(fractionDigits: 3))\n"
                            }
                        } else {
                            let spreading = nestedGoal.sji(chunk) * model.dm.goalActivation
                            if spreading > 0 {
                                s += "   Spreading \(spreading.string(fractionDigits: 3)) from slot \(slot) with value \(nestedGoal.name),  Sji = \(nestedGoal.sji(chunk).string(fractionDigits: 3))\n"
                            }
                        }
                    }
                }
            }
            s += spreadingFromBufferDescription(bufferName: "input", spreadingParameterValue: model.dm.inputActivation, chunk: chunk, divideBySlots: true).0
            s += spreadingFromBufferDescription(bufferName: "retrievalH", spreadingParameterValue: model.dm.retrievalActivation, chunk: chunk, divideBySlots: true).0
            s += spreadingFromBufferDescription(bufferName: "imaginal", spreadingParameterValue: model.dm.imaginalActivation, chunk: chunk, divideBySlots: true).0
            chunkTexts[chunk.name] = s
        }
    }
    
}
