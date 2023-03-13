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
//            CommandGroup(before: .newItem) {
//                            Button("Load model...") {
//                                architecture.loadModels()
//                            }
//                        }
            CommandGroup(replacing: CommandGroupPlacement.newItem) {
                Button("Load model...") {
                    architecture.loadModels()
                }
                Button("Run batch...") {
                    architecture.runBatch()
                }
            }
            
        }
    }
}
