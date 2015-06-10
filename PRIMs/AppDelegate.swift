//
//  AppDelegate.swift
//  PRIMs
//
//  Created by Niels Taatgen on 4/17/15.
//  Copyright (c) 2015 Niels Taatgen. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }

    func application(sender: NSApplication, openFile filename: String) -> Bool {
        let url = NSURL(fileURLWithPath: filename)
        if let storyboard = NSStoryboard(name: "Main", bundle: nil) {
            if let controller = storyboard.instantiateControllerWithIdentifier("PRIMs") as? MainViewController {
                let url = NSURL(fileURLWithPath: filename)
                if url == nil { return false }
                return controller.loadModelWithString(url!)
            }
            
            
        }
        return false
    }

    
}

