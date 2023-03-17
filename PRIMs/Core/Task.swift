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
    let number: Int
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
    var bugged: Bool = false
    init(name: String, number: Int, path: URL) {
        self.name = name
        self.number = number
        self.filename = path
    }
}
