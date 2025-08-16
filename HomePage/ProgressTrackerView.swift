//
//  ProgressTrackerView.swift
//  Fit Pantry
//
//  Created by Lexie Reddon on 12/1/24.
//

import SwiftUI
import Charts



struct ProgressTrackerView: View {
    
    struct MonthlybodyWeight: Identifiable {
        var id: Date {date}
        var date: Date
        var weight: Double
        
        init(month: Int, weight: Double){
            let calendar = Calendar.autoupdatingCurrent
            self.date = calendar.date(from: DateComponents(year: 2024, month:month))!
            self.weight = weight
        }
        
        
    }

    //static data for now. Will need to link to logged data later.

    var data: [MonthlybodyWeight] = [
        MonthlybodyWeight(month: 1, weight: 150),
        MonthlybodyWeight(month: 2, weight: 152),
        MonthlybodyWeight(month: 3, weight: 148),
        MonthlybodyWeight(month: 9, weight: 130),
        
        
    ]
    
    var body: some View {
        VStack{
            Chart(data) {
                LineMark(
                    x: .value("Month", $0.date),
                    y: .value("Body Weight", $0.weight)
                )
            }
            .frame(width: 300, height: 200)
            .chartXAxisLabel("Month")
            .chartXAxis{
                AxisMarks(values: .stride(by: .month))
            }
            .chartYAxisLabel("Body Weight (lbs)")
            .chartYAxis{
               
                AxisMarks(values: .stride(by: 50))
            }
        }.padding(80)
        .border(Color.gray, width: 1)
        
    }
}



struct ProgressTrackerView_Previews: PreviewProvider {
    static var previews: some View {
        ProgressTrackerView()
    }
}
