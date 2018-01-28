//
//  DateConv.swift
//  Dashi
//
//  Created by Chris Henk on 1/28/18.
//  Copyright © 2018 Senior Design. All rights reserved.
//

import Foundation

struct DateConv {
    
    private static var dateFormatter: DateFormatter? = nil
    
    private static func initialize() {
        self.dateFormatter = DateFormatter()
        self.dateFormatter!.dateFormat = "yyyy-MM-dd HH:mm:ss"
    }
    
    public static func toDate(timestamp: String) -> Date {
        if self.dateFormatter == nil {
            self.initialize()
        }
        
        return self.dateFormatter!.date(from: timestamp)!
    }
    
    public static func toString(date: Date) -> String {
        if self.dateFormatter == nil {
            self.initialize()
        }
        
        return self.dateFormatter!.string(from: date)
    }
}
