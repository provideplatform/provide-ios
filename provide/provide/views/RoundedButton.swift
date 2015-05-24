//
//  RoundedButton.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

class RoundedButton: UIButton {

    var initialBackgroundColor: UIColor! {
        didSet {
            backgroundColor = initialBackgroundColor
        }
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        initialBackgroundColor = Color.darkBlueBackground()

        roundCorners(5.0)

        addTarget(self, action: "onTouchUpInside:", forControlEvents: .TouchUpInside)
    }

    var titleText: String = "" {
        didSet {
            titleLabel!.text = titleText
        }
    }

    override var highlighted: Bool {
        didSet {
            if highlighted == true {
                backgroundColor = UIColor.darkGrayColor()
            } else {
                backgroundColor = initialBackgroundColor
            }
        }
    }

    // MARK: Action bindings

    var onTouchUpInsideCallback: VoidBlock!

    func onTouchUpInside(sender: RoundedButton!) {
        if let callback = onTouchUpInsideCallback {
            callback()
        }
    }

}
