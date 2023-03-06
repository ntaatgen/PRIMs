//
//  PublicChunk.swift
//  ACT-R-SU
//
//  Created by Niels Taatgen on 1/17/23.
//

import Foundation

/// struct to represent Chunks so that they can be display in the View
struct PublicChunk: Identifiable, CustomStringConvertible {
    var name: String
    var slots: [(slot: String,val: String)]
    var activation: Double
    var id: Int
    var description: String {
        get {
            var s = "\(name)\n"
            for (slot, val) in slots {
                s += "  \(slot)  \(val)\n"
            }
            return s
        }
    }
}
