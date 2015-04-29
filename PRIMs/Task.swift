//
//  Task.swift
//  PRIMs
//
//  Created by Niels Taatgen on 4/28/15.
//  Copyright (c) 2015 Niels Taatgen. All rights reserved.
//

import Foundation

class Task {
    let name: String
    var loaded: Bool = false
    var inputs: [Chunk] = []
//    var inputOutput: { (action: [Val]) -> Chunk?) }
    let filename: NSURL
    
    init(name: String, path: NSURL) {
        self.name = name
        self.filename = path
    }
}