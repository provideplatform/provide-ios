//
//  RoundedButton.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2019 Provide Technologies Inc. All rights reserved.
//

import UIKit

class RoundedButton: UIButton {

    private var initialBackgroundColor: UIColor!

    override func awakeFromNib() {
        super.awakeFromNib()

        initialBackgroundColor = Color.darkBlueBackground()

        roundCorners(5.0)

        addTarget(self, action: #selector(onTouchUpInside(_:)), for: .touchUpInside)
    }

    override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? .darkGray : initialBackgroundColor
        }
    }

    // MARK: Action bindings

    var onTouchUpInsideCallback: VoidBlock!

    @objc func onTouchUpInside(_ sender: RoundedButton) {
        onTouchUpInsideCallback?()
    }
}
