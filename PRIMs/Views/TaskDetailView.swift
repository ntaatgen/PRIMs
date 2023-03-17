//
//  TaskDetailView.swift
//  PRIMs
//
//  Created by Niels Taatgen on 3/4/23.
//

import SwiftUI

struct TaskDetailView: View {
    var task: Task
    @ObservedObject var model: PRIMsViewModel
    var body: some View {
        HStack {
            if task.imageURL != nil {
                Image(nsImage: NSImage(contentsOfFile: task.imageURL!.path)!)
                    .resizable()
                    .frame(width: 50, height: 50)
            } else {
                Image("Question")
                    .resizable()
                    .frame(width: 50, height: 50)
            }
//            if task.name == model.currentTask {
//                Image(systemName: "play.fill")
//                    .foregroundColor(Color.red)
//            } else
            if task.loaded {
                Image(systemName: "play.fill")
                    .foregroundColor(numberToColor(task.number))
            } else {
                Image(systemName: "stop")
            }
            Text(task.name)
                .font(.title)
            if task.name == model.currentTask && !task.bugged {
                Image(systemName: "record.circle.fill")
                    .foregroundColor(Color.red)

            }
            if task.bugged {
                Image(systemName: "ant.fill")
                    .foregroundColor(Color.red)
                Text("Bugged!")
                    .font(.caption2)
            }
            
        }
        .onTapGesture {
            model.setCurrentTask(task: task)
        }
    }
}

