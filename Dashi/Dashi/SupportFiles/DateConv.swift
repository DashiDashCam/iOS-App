//
//  DateConv.swift
//  Dashi
//
//  Created by Chris Henk on 1/28/18.
//  Copyright © 2018 Senior Design. All rights reserved.
//

import Foundation

struct DateConv {

    private static var dateFormatter: DateFormatter?

    private static func initialize() {
        dateFormatter = DateFormatter()
        dateFormatter!.dateFormat = "yyyy-MM-dd HH:mm:ss"
    }

    public static func toDate(timestamp: String) -> Date {
        if dateFormatter == nil {
            initialize()
        }

        return dateFormatter!.date(from: timestamp)!
    }

    public static func toString(date: Date) -> String {
        if dateFormatter == nil {
            initialize()
        }

        return dateFormatter!.string(from: date)
    }
}
