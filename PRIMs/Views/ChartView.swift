//
//  ChartView.swift
//  PRIMs
//
//  Created by Niels Taatgen on 3/4/23.
//

import SwiftUI
import Charts
@available(macOS 13.0,*)
struct ChartView: View {
    @ObservedObject var model: PRIMsViewModel
    @State var graphData: Int = 1
    var body: some View {
        VStack {

                Picker("Shown Data", selection: $graphData) {
                    Text("Model results").tag(1)
                    Text("Operator activations").tag(2)
                }
                .onChange(of: graphData, perform: { tag in model.changeChartData(level: tag)})
            
            if model.chartTitle != "" {
                Text(model.chartTitle)
            }
            Chart(model.modelResults) {
                LineMark(x: .value("Trial", $0.x),
                         y: .value("Time (sec)",$0.y),
                         series: .value("run",$0.run)
                )
                .foregroundStyle(by: .value("Task", $0.task))
                .symbol(by: .value("Task", $0.task))
                .symbolSize(30)
            }
        }
    }
}
