//
//  GMSMapModel.swift
//  GMSMapDemo
//
//  Created by wxliu on 2024/5/8.
//

import Foundation

enum GMSMapUserNavigateState {
case noStart
case navigating
case finished
    
var navigateing: Bool {
    get {
        return self == .navigating
    }
}
}

struct GMSMapNavigateInfo {
    var startTime: TimeInterval = 0.0
    var duration: TimeInterval = 0.0
    var totalDistance: Double = 0.0
    var remainingDistance: Double = 0.0
    
    mutating func reset() {
        self.startTime = 0.0
        self.duration = 0.0
        self.totalDistance = 0.0
        self.remainingDistance = 0.0
    }
    
    func getDurationFormatStr()->String {
        let hours = Int(duration / 3600)
        let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
        let seconds = Int(duration.truncatingRemainder(dividingBy: 60))
            
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    func getStartFormatStr(format: String = "yyyy-MM-dd HH:mm:ss") -> String {
        let date = Date(timeIntervalSince1970: startTime)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: date)
    }
}
