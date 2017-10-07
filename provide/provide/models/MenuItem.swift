//
//  MenuItem.swift
//  provide
//
//  Created by Kyle Thomas on 12/18/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import Foundation

class MenuItem: NSObject {

    var label: String!
    var storyboard: String!
    var urlString: String!
    var action: String!

    init(label: String, action: String? = nil, urlString: String? = nil, storyboard: String? = nil) {
        self.label = label
        self.action = action
        self.urlString = urlString
        self.storyboard = storyboard
    }

    var url: URL! {
        if let urlString = urlString {
            return URL(string: urlString)
        }
        return nil
    }

    var selector: Selector! {
        if let action = action {
            return Selector(action)
        }
        return nil
    }

    init(item: [String: String]) {
        super.init()

        label = item["label"]
        storyboard = item["storyboard"]
        urlString = item["url"]
        action = item["action"]
    }
}
