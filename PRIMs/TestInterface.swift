//
//  TestInterface.swift
//  PRIMs
//
//  Created by Niels Taatgen on 5/11/15.
//  Copyright (c) 2015 Niels Taatgen. All rights reserved.
//

import Foundation


func testInterface() -> PRScreen {
    let screen = PRScreen()
    let card = PRObject(attributes: ["card"], superObject: nil)
    screen.object = card
    screen.currentParentObject = card
    let acq1 = PRObject(attributes: ["acquarium","left"], superObject: card)
    let acq2 = PRObject(attributes: ["acquarium","right"], superObject: card)
    let fish1 = PRObject(attributes: ["fish","red"], superObject: acq1)
    let fish2 = PRObject(attributes: ["fish","blue"], superObject: acq1)
    let fish3 = PRObject(attributes: ["fish","red"], superObject: acq1)
    let fish4 = PRObject(attributes: ["fish","red"], superObject: acq1)
    let fish5 = PRObject(attributes: ["fish","red"], superObject: acq2)
    let fish6 = PRObject(attributes: ["fish","blue"], superObject: acq2)
    let fish7 = PRObject(attributes: ["fish","green"], superObject: acq2)
    let fish8 = PRObject(attributes: ["fish","red"], superObject: acq2)
    return screen
}