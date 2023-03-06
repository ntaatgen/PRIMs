//
//  Instantiation.swift
//  actr
//
//  Created by Niels Taatgen on 3/21/15.
//  Copyright (c) 2015 Niels Taatgen. All rights reserved.
//

import Foundation

struct Instantiation {
    let p: Production
//    var mapping: [String:Value] = [:]
    var u: Double
    var time: Double
    
    init(prod: Production, time: Double, u: Double) {
        self.p = prod
        self.u = u
        self.time = time
    }
    
}