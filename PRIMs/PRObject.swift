//
//  PRObject.swift
//  PRIMs
//
//  Created by Niels Taatgen on 5/11/15.
//  Copyright (c) 2015 Niels Taatgen. All rights reserved.
//

import Foundation

class PRObject{
    let attributes: [String]
    let superObject: PRObject?
    let name: String
    var subObjects: [PRObject] = []
    var attended = 0
    
    init(name: String, attributes: [String], superObject: PRObject?) {
        self.name = name
        self.attributes = attributes
        self.superObject = superObject
        if superObject != nil {
            superObject!.subObjects.append(self)
        }
    }
 
        
    func chunk(model: Model) -> Chunk {
        let chunk = model.generateNewChunk(s1: "perception")
        chunk.setSlot("isa", value: "fact")
        for i in 0..<attributes.count {
            chunk.setSlot("slot\(i + 1)", value: attributes[i])
        }
        return chunk
    }
    
}