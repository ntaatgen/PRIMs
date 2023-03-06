//
//  Task.swift
//  PRIMs
//
//  Created by Niels Taatgen on 4/28/15.
//  Copyright (c) 2015 Niels Taatgen. All rights reserved.
//

import Foundation

class Task: Identifiable {
    let name: String
    var id = UUID()
    var loaded: Bool = false
//    var inputOutput: { (action: [Val]) -> Chunk?) }
    let filename: URL
    var goalChunk: Chunk? = nil
    var goalConstants: Chunk? = nil
    var scenario: PRScenario! = nil
    var reward: Double = 10.0
    var parameters: [(String,String)] = []
    var actions: [String:ActionInstance] = [:]
    var imageURL: URL?
    init(name: String, path: URL) {
        self.name = name
        self.filename = path
    }
}
