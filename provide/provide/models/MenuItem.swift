//
//  MenuItem.swift
//  provide
//
//  Created by Kyle Thomas on 12/18/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import Foundation

class MenuItem: NSObject {

    var label: String
    var storyboard: String?
    private var urlString: String?
    private var actionString: String?

    init(label: String, action: String? = nil, urlString: String? = nil, storyboard: String? = nil) {
        self.label = label
        self.actionString = action
        self.urlString = urlString
        self.storyboard = storyboard
    }

    var url: URL? {
        return urlString.flatMap { URL(string: $0) }
    }

    var selector: Selector? {
        return actionString.flatMap { Selector($0) }
    }

    convenience init(item: [String: String]) {
        self.init(label: item["label"]!)

        storyboard = item["storyboard"]
        urlString = item["url"]
        actionString = item["action"]
    }
}
