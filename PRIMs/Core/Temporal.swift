//
//  Temporal.swift
//  PRIMs
//
//  Created by Niels Taatgen on 5/27/17.
//  Copyright © 2017 Niels Taatgen. All rights reserved.
//

import Foundation

/// T0 is the duration of the start pulse
/// Tn+1 = aTn + noise(SD = b * a * Tn)
/// The temporal module has three parameters:
/// time-t0: the start time (default 0.011 or 0.1)
/// time-a: the a parameter (default 1.1 or 1.02)
/// time-b: the b parameter (default 0.015)
///
/// The temporal buffer is called T
/// if the timer is active, T1 has the current pulse count
/// T2 is set to T (true) each time the timer is incremented, the model can set it to nil to indiciate
/// the time has been attended
/// The timer is activated by putting "start" in T3
/// Putting "stop" in T3 stops the timer
/// Any match made against T1 will be successful if T1 is greater or equal to the
/// time that it is compared to

class Temporal {
    static let timeT0Default = 0.011
    static let timeADefault = 1.1
    static let timeBDefault = 0.015
    unowned let model: Model
    var timeT0 = timeT0Default
    var timeA = timeADefault
    var timeB = timeBDefault
    var currentPulse: Int? = nil
    var currentPulseLength: Double? = nil
    var startTime: Double? = nil
    var nextPulseTime: Double? = nil
    
    init(model: Model) {
        self.model = model
    }
    
    func setParametersToDefault() {
        timeT0 = Temporal.timeT0Default
        timeA = Temporal.timeADefault
        timeB = Temporal.timeBDefault
    }
    
    func startTimer() {
        currentPulse = 0
        startTime = model.time
        nextPulseTime = timeT0
        currentPulseLength = timeT0
        let timeChunk = Chunk(s: model.generateName("time"), m: model)
        timeChunk.setSlot("isa", value: "time")
        timeChunk.setSlot("slot1", value: 0)
        model.buffers["temporal"] = timeChunk
    }
    
    func action() {
        guard let timeChunk = model.buffers["temporal"] else { return }
        if let command = timeChunk.slotValue("slot3") {
            switch command.description {
            case "start":
                startTimer()
                return
            case "stop":
                stopTimer()
                return
            default:
                model.addToTraceField("Unknown command /(command.description) to temporal module")
                return
            }
        }
    }
    
    func updateTimer() {
       guard let timeChunk = model.buffers["temporal"] else { return }
       guard startTime != nil && nextPulseTime != nil else { return }
        if model.time > startTime! + nextPulseTime! {
            while model.time > startTime! + nextPulseTime! {
                currentPulse = currentPulse! + 1
                print("Incrementing pulse to \(currentPulse!) at time \(model.time - startTime!)")
                currentPulseLength = timeA * currentPulseLength! + actrNoise(timeB * timeA * currentPulseLength!)
                nextPulseTime = nextPulseTime! + currentPulseLength!
            }
            timeChunk.setSlot("slot1", value: Double(currentPulse!))
            timeChunk.setSlot("slot2", value: "true")
        }
    }
    
    func compareTime(compareValue: Double?) -> Bool {
        guard let timeChunk = model.buffers["temporal"] else { return false }
        guard compareValue != nil else { return false }
        return (timeChunk.slotValue("slot1")?.number()!)! >= compareValue!
    }
    
    func stopTimer() {
        model.buffers["temporal"] = nil
        reset()
    }
    
    func reset() {
        currentPulse = nil
        currentPulseLength = nil
        startTime = nil
    }
    
}
