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
    let controller: MainViewController
    let directory: NSURL
    var progress: Double = 0.0
    
    init(script: String, outputFile: NSURL, model: Model, controller: MainViewController, directory: NSURL) {
        self.batchScript = script
        self.outputFileName = outputFile
        self.model = model
        self.controller = controller
        self.directory = directory
    }
    
    func runScript() {
        var scanner = NSScanner(string: batchScript)
        let whiteSpaceAndNL = NSMutableCharacterSet.whitespaceAndNewlineCharacterSet()
        let repeat = scanner.scanUpToCharactersFromSet(whiteSpaceAndNL)
        let numberOfRepeats = scanner.scanInt()
        if numberOfRepeats == nil {
            model.addToTraceField("Illegal number of repeats")
            return
        }
        var newfile = true
        for i in 0..<numberOfRepeats! {
            println("Run #\(i)")
            
            scanner = NSScanner(string: self.batchScript)
            
            while let command = scanner.scanUpToCharactersFromSet(whiteSpaceAndNL) {
                switch command {
                case "run":
                    let taskname = scanner.scanUpToCharactersFromSet(whiteSpaceAndNL)
                    if taskname == nil {
                        self.model.addToTraceField("Illegal task name in run")
                        return
                    }
                    let taskLabel = scanner.scanUpToCharactersFromSet(whiteSpaceAndNL)
                    if taskLabel == nil {
                        self.model.addToTraceField("Illegal task label in run")
                        return
                    }
                    let numberOfTrials = scanner.scanInt()
                    if numberOfTrials == nil {
                        self.model.addToTraceField("Illegal number of trials in run")
                        return
                    }
                    self.model.addToTraceField("Running task \(taskname!) with label \(taskLabel!) for \(numberOfTrials!) trials")
                    var tasknumber = self.model.findTask(taskname!)
                    if tasknumber == nil {
                        let taskPath = self.directory.URLByAppendingPathComponent(taskname! + ".prims")
                        println("Trying to load \(taskPath)")
                        if !self.controller.loadModelWithString(taskPath) {
                            self.model.addToTraceField("Task \(taskname!) is not loaded nor can it be found")
                            return
                        }
                        tasknumber = self.model.findTask(taskname!)
                    }
                    self.model.loadOrReloadTask(tasknumber!)
                    for j in 0..<numberOfTrials! {
                        println("Trial #\(j)")
                        self.model.run()
                        var output: String = ""
                        for line in self.model.outputData {
                            output += "\(i) \(taskname!) \(taskLabel!) \(j) \(line.time) \(line.eventType) \(line.eventParameter1) \(line.eventParameter2) \(line.eventParameter3) "
                            for item in line.inputParameters {
                                output += item + " "
                            }
                            output += "\n"
                        }
                        if !newfile {
                            if NSFileManager.defaultManager().fileExistsAtPath(self.outputFileName.path!) {
                                var err:NSError?
                                if let fileHandle = NSFileHandle(forWritingToURL: self.outputFileName, error: &err) {
                                    fileHandle.seekToEndOfFile()
                                    let data = output.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
                                    fileHandle.writeData(data!)
                                    fileHandle.closeFile()
                                }
                                else {
                                    self.model.addToTraceField("Can't open fileHandle \(err)")
                                }
                            }
                        }
                        else {
                            newfile = false
                            var err:NSError?
                            if !output.writeToURL(self.outputFileName, atomically: false, encoding: NSUTF8StringEncoding, error: &err) {
                                self.model.addToTraceField("Can't write datafile \(err)")
                                
                            }
                        }
                    }
                case "reset":
                    println("Resetting models")
                    self.model.reset(nil)
                case "repeat":
                    scanner.scanInt()
                default: break
                    
                }
            }
            progress = 100 * (Double(i) + 1) / Double(numberOfRepeats!)
            NSNotificationCenter.defaultCenter().postNotificationName("progress",object: nil)

        }
        
        
    }
    
    
}