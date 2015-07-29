//
//  Operator.swift
//  PRIMs
//
//  Created by Niels Taatgen on 7/28/15.
//  Copyright (c) 2015 Niels Taatgen. All rights reserved.
//

import Foundation

/**
    The Operator class contains many of the functions that deal with operators. Most of these still have to be migrated from Model.swift
*/
class Operator {
    /// This Array has all the operators with arrays of their conditions and actions. We use this to find the optimal ovelap when defining new operators
    var operatorCA: [(String,[String],[String])] = []
    let model: Model
    
    init(model: Model) {
        self.model = model
    }

    /**
    Reset the operator object
    */
    func reset() {
        operatorCA = []
    }
    
    
    /**
    Determine the amount of overlap between two lists of PRIMs
    */
    func determineOverlap(oldList: [String], newList: [String]) -> Int {
        var count = 0
        for prim in oldList {
            if !contains(newList, prim) {
                return count
            }
            count++
        }
        return count
    }
    
    /**
    Construct a string of PRIMs from the best matching operators
    */
    func constructList(template: [String], source: [String], overlap: Int) -> (String, [String]) {
        var primList = ""
        var primArray = [String]()
        if overlap > 0 {
            for i in 0..<overlap {
                primList =  (primList == "" ? template[i] : template[i] + ";" ) + primList
                primArray.append(template[i])
            }
        }
        for prim in source {
            if !contains(primArray, prim) {
                primList = (primList == "" ? prim : prim + ";" ) + primList
                primArray.append(prim)
            }
        }
        return (primList, primArray)
    }
    
    
    /**
    Add conditions and actions to an operator while trying to optimize the order of the PRIMs to maximize overlap with existing operators 
    */
    func addOperator(op: Chunk, conditions: [String], actions: [String]) {
        var bestConditionMatch: [String] = []
        var bestConditionNumber: Int = -1
        var bestConditionActivation: Double = -1000
        var bestActionMatch: [String] = []
        var bestActionNumber: Int = -1
        var bestActionActivation: Double = -1000
        for (chunkName, chunkConditions, chunkActions) in operatorCA {
            if let chunkActivation = model.dm.chunks[chunkName]?.baseLevelActivation() {
                let conditionOverlap = determineOverlap(chunkConditions, newList: conditions)
                if (conditionOverlap > bestConditionNumber) || (conditionOverlap == bestConditionNumber && chunkActivation > bestConditionActivation) {
                    bestConditionMatch = chunkConditions
                    bestConditionNumber = conditionOverlap
                    bestConditionActivation = chunkActivation
                }
                let actionOverlap = determineOverlap(chunkActions, newList: actions)
                if (actionOverlap > bestActionNumber) || (actionOverlap == bestActionNumber && chunkActivation > bestActionActivation) {
                    bestActionMatch = chunkActions
                    bestActionNumber = actionOverlap
                    bestActionActivation = chunkActivation
                }
            }
        }
        let (conditionString, conditionList) = constructList(bestConditionMatch, source: conditions, overlap: bestConditionNumber)
        let (actionString, actionList) = constructList(bestActionMatch, source: actions, overlap: bestActionNumber)
        op.setSlot("condition", value: conditionString)
        op.setSlot("action", value: actionString)
        operatorCA.append((op.name, conditionList, actionList))
    }
    
}