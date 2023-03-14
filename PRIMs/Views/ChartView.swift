//
//  ChartView.swift
//  PRIMs
//
//  Created by Niels Taatgen on 3/4/23.
//

import SwiftUI
import Charts

struct ChartView: View {
    @ObservedObject var model: PRIMsViewModel
    var body: some View {
        VStack {
            if model.chartTitle != "" {
                Text(model.chartTitle)
            }
            Chart(model.modelResults) {
                LineMark(x: .value("Trial", $0.x),
                         y: .value("Time (sec)",$0.y),
                         series: .value("run",$0.run)
                )
                .foregroundStyle(by: .value("Task", $0.task))
                
            }
        }
    }
}

struct ChartView_Previews: PreviewProvider {
    static var previews: some View {
        ChartView(model: PRIMsViewModel())
    }
}
