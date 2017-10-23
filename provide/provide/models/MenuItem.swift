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

    init(label: String, action: String? = nil, urlString: String? = nil, storyboard: String? = nil) {
        self.label = label
        self.actionString = action
        self.urlString = urlString
        self.storyboard = storyboard
    }

    convenience init(label: String, action: Selector, urlString: String? = nil) {
        self.init(label: label, action: action.description, urlString: urlString)
    }

    convenience init(dict: [String: String]) {
        self.init(label: dict["label"]!, action: dict["action"], urlString: dict["url"], storyboard: dict["storyboard"])
    }

    var url: URL? {
        return urlString.flatMap { URL(string: $0) }
    }

    var selector: Selector? {
        return actionString.flatMap { Selector($0) }
    }
}
