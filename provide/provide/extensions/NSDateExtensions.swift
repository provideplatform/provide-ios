//
//  NSDateExtensions.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

extension NSDate {

    override public var debugDescription: String {
        return NSDateFormatter(dateFormat: "yyyy-MM-dd HH:mm:ss a").stringFromDate(self)
    }

    class func fromString(string: String) -> NSDate! {
        let dateFormatter = NSDateFormatter(dateFormat: "yyyy-MM-dd'T'HH:mm:ssZZ")
        return dateFormatter.dateFromString(string)
    }

    func format(dateFormat: String) -> String {
        let dateFormatter = NSDateFormatter()
        dateFormatter.timeZone = NSTimeZone(name: "UTC")
        dateFormatter.dateFormat = dateFormat
        return dateFormatter.stringFromDate(self)
    }

    var timeString: String? {
        let dateFormatter = NSDateFormatter(dateFormat: "hh:mm a")
        return dateFormatter.stringFromDate(self)
    }

    var minutes: Int {
        return NSCalendar.currentCalendar().components(.Minute, fromDate: self).minute
    }

    var minutesString: String {
        var str = String(minutes)
        if minutes < 10 {
            str = "0\(str)"
        }
        return str
    }

    func secondsSince(date: NSDate) -> NSTimeInterval {
        let seconds = NSDate().timeIntervalSinceDate(date)
        return round(seconds * 100) / 100
    }

    var utcString: String {
        return format("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")
    }

    var monthName: String {
        let dateFormatter = NSDateFormatter(dateFormat: "MMMM")
        return dateFormatter.stringFromDate(self)
    }

    var atMidnight: NSDate {
        let componentsWithoutTime = NSCalendar.currentCalendar().components([.Year, .Month, .Day], fromDate: self)
        return NSCalendar.currentCalendar().dateFromComponents(componentsWithoutTime)!
    }

    var dayOfWeek: String {
        let dateFormatter = NSDateFormatter(dateFormat: "EEEE")
        return dateFormatter.stringFromDate(self)
    }

    var yearString: String {
        let dateFormatter = NSDateFormatter(dateFormat: "yyyy")
        return dateFormatter.stringFromDate(self)
    }
}
