//
//  NSDateFormatterExtensions.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

extension NSDateFormatter {

    convenience init(dateFormat: String) {
        self.init()
        self.dateFormat = dateFormat
    }

    convenience init(dateStyle: NSDateFormatterStyle) {
        self.init()
        self.dateStyle = dateStyle
    }

    class func localizedStringFromDate(date: NSDate, dateStyle: NSDateFormatterStyle) -> String {
        return NSDateFormatter.localizedStringFromDate(date, dateStyle: dateStyle, timeStyle: .NoStyle)
    }

}
