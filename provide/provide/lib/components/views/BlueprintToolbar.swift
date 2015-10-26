//
//  BlueprintToolbar.swift
//  provide
//
//  Created by Kyle Thomas on 10/26/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

protocol BlueprintToolbarDelegate {
    func blueprintToolbar(toolbar: BlueprintToolbar, shouldSetNavigatorVisibility visible: Bool)
}

class BlueprintToolbar: UIToolbar {

    var blueprintToolbarDelegate: BlueprintToolbarDelegate!

    private var navigatorVisible = false

    @IBOutlet private weak var navigationButton: UIBarButtonItem! {
        didSet {
            if let navigationButton = navigationButton {
                navigationButton.target = self
                navigationButton.action = "toggleNavigatorVisibility:"
            }
        }
    }

    func toggleNavigatorVisibility(sender: UIBarButtonItem) {
        navigatorVisible = !navigatorVisible
        blueprintToolbarDelegate?.blueprintToolbar(self, shouldSetNavigatorVisibility: navigatorVisible)
    }
}
