//
//  TaskView.swift
//  PRIMs
//
//  Created by Niels Taatgen on 3/4/23.
//

import SwiftUI

struct TaskView: View {
    @ObservedObject var model: PRIMsViewModel
    var body: some View {
        VStack {
            Text("Task list")
                .font(.title)
            List(model.tasks) {task in
                TaskDetailView(task: task, model: model)
            }
            .listStyle(.bordered(alternatesRowBackgrounds: true))
        }
    }
}

