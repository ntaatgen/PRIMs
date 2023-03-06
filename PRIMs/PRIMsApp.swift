//
//  PRIMsApp.swift
//  PRIMs
//
//  Created by Niels Taatgen on 3/2/23.
//

import SwiftUI

@main
struct PRIMsApp: App {
    let architecture = PRIMsViewModel()
    var body: some Scene {
        WindowGroup {
            MainContentView(model: architecture)
        }
        .commands {
            ToolbarCommands()
            CommandGroup(before: .newItem) {
                            Button("Load model...") {
                                architecture.loadModels()
                            }
                        }
        }
    }
}
