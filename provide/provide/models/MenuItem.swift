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

    init(item: [String : String]) {
        super.init()

        if let label = item["label"] {
            self.label = label
        }

        if let storyboard = item["storyboard"] {
            self.storyboard = storyboard
        }

        if let urlString = item["url"] {
            self.urlString = urlString
        }

        if let action = item["action"] {
            self.action = action
        }
    }
}
