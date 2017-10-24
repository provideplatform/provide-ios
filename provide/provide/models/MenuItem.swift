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
    var urlString: String?
    var actionString: String?

    var url: URL? {
        return urlString.flatMap { URL(string: $0) }
    }

    var selector: Selector? {
        return actionString.flatMap { Selector($0) }
    }

    private init(label: String) {
        self.label = label
    }

    convenience init(label: String, action: Selector) {
        self.init(label: label)
        self.actionString = action.description
    }

    convenience init(label: String, action: String) {
        self.init(label: label)
        self.actionString = action
    }

    convenience init(label: String, urlString: String) {
        self.init(label: label)
        self.urlString = urlString
    }

    convenience init(label: String, storyboard: String) {
        self.init(label: label)
        self.storyboard = storyboard
    }

    convenience init(dict: [String: String]) {
        self.init(label: dict["label"]!)
        self.actionString = dict["action"]
        self.urlString = dict["url"]
        self.storyboard = dict["storyboard"]
    }
}
