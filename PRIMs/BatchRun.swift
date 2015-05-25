//
//  BatchRun.swift
//  PRIMs
//
//  Created by Niels Taatgen on 5/22/15.
//  Copyright (c) 2015 Niels Taatgen. All rights reserved.
//

import Foundation

class BatchRun {
    let batchScript: String
    let outputFileName: NSURL
    let model: Model
    
    init(script: String, outputFile: NSURL, model: Model) {
        self.batchScript = script
        self.outputFileName = outputFile
        self.model = model
    }
    
    func runScript() {
        var scanner = NSScanner(string: batchScript)
        let whiteSpaceAndNL = NSMutableCharacterSet.whitespaceAndNewlineCharacterSet()
        let repeat = scanner.scanUpToCharactersFromSet(whiteSpaceAndNL)
        let numberOfRepeats = scanner.scanInt()
        if numberOfRepeats == nil {
            println("Illegal number of repeats")
            return
        }
        model.tracing = false
        var newfile = true
        for i in 0..<numberOfRepeats! {
            println("Run #\(i)")
            
            scanner = NSScanner(string: batchScript)
            
            while let command = scanner.scanUpToCharactersFromSet(whiteSpaceAndNL) {
                switch command {
                case "run":
                    let taskname = scanner.scanUpToCharactersFromSet(whiteSpaceAndNL)
                    if taskname == nil {
                        println("Illegal task name in run")
                        return
                    }
                    let taskLabel = scanner.scanUpToCharactersFromSet(whiteSpaceAndNL)
                    if taskLabel == nil {
                        println("Illegal task label in run")
                        return
                    }
                    let numberOfTrials = scanner.scanInt()
                    if numberOfTrials == nil {
                        println("Illegal number of trials in run")
                        return
                    }
                    println("Running task \(taskname!) with label \(taskLabel!) for \(numberOfTrials!) trials")
                    let tasknumber = model.findTask(taskname!)
                    if tasknumber == nil {
                        println("Task \(taskname!) is not loaded")
                        return
                    }
                    model.loadOrReloadTask(tasknumber!)
                    for j in 0..<numberOfTrials! {
                        println("Trial #\(j)")
                        model.run()
                        var output: String = ""
                        for line in model.outputData {
                            output += "\(i) \(taskname!) \(taskLabel!) \(j) \(line.time) \(line.eventType) \(line.eventParameter1) \(line.eventParameter2) \(line.eventParameter3)\n"
                        }
                        if !newfile {
                            if NSFileManager.defaultManager().fileExistsAtPath(outputFileName.path!) {
                                var err:NSError?
                                if let fileHandle = NSFileHandle(forWritingToURL: outputFileName, error: &err) {
                                    fileHandle.seekToEndOfFile()
                                    let data = output.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
                                    fileHandle.writeData(data!)
                                    fileHandle.closeFile()
                                }
                                else {
                                    println("Can't open fileHandle \(err)")
                                }
                            }
                        }
                        else {
                            newfile = false
                            var err:NSError?
                            if !output.writeToURL(outputFileName, atomically: false, encoding: NSUTF8StringEncoding, error: &err) {
                                println("Can't write datafile \(err)")
                                
                            }
                        }
                    }
                case "reset":
                    println("Resetting models")
                    model.reset(nil)
                case "repeat":
                    scanner.scanInt()
                default: break
                    
                }
            }
        }
    }
    
    
    
}