//
//  RoundedButton.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit

class RoundedButton: UIButton {

    var initialBackgroundColor: UIColor! {
        didSet {
            backgroundColor = initialBackgroundColor
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        initialBackgroundColor = Color.darkBlueBackground()

        roundCorners(5.0)

        addTarget(self, action: #selector(onTouchUpInside(_:)), for: .touchUpInside)
    }

    var titleText: String = "" {
        didSet {
            titleLabel!.text = titleText
        }
    }

    override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? .darkGray : initialBackgroundColor
        }
    }

    // MARK: Action bindings

    var onTouchUpInsideCallback: VoidBlock!

    func onTouchUpInside(_ sender: RoundedButton) {
        onTouchUpInsideCallback()
    }
}
