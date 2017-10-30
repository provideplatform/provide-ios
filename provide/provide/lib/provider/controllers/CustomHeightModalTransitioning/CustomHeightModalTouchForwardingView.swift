//
//  CustomHeightModalTouchForwardingView.swift
//  provide
//
//  Created by Jawwad Ahmad on 10/30/17.
//  Copyright © 2017 Provide Technologies Inc. All rights reserved.
//

import UIKit

final class CustomHeightModalTouchForwardingView: UIView {

    final var passthroughView: UIView!

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let hitView = super.hitTest(point, with: event) else { return nil }
        guard hitView == self else { return hitView }

        let point = convert(point, to: passthroughView)
        if let passthroughHitView = passthroughView.hitTest(point, with: event) {
            return passthroughHitView
        }

        return self
    }
}
