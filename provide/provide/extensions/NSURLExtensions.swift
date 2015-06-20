//
//  NSURLExtensions.swift
//  provide
//
//  Created by Kyle Thomas on 5/30/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

extension NSURL {

    convenience init!(_ urlString: String) {
        self.init(string: urlString)
    }
}
