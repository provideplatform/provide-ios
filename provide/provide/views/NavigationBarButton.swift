//
//  NavigationBarButton.swift
//  provide
//
//  Created by Kyle Thomas on 7/26/15.
//  Copyright © 2019 Provide Technologies Inc. All rights reserved.
//

import UIKit

class NavigationBarButton: UIButton {

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    class func barButtonItemWithImage(_ image: UIImage, target: Any?, action: Selector, tintColor: UIColor = Color.applicationDefaultBarButtonItemTintColor(), badge: Int = 0) -> UIBarButtonItem {
        let button = NavigationBarButton(type: .custom)
        button.frame = CGRect(x: 0.0, y: 0.0, width: image.width, height: image.height)
        button.setBackgroundImage(image.withRenderingMode(.alwaysTemplate), for: UIControlState())
        button.tintColor = tintColor
        button.addTarget(target, action: action, for: .touchUpInside)

        let item = UIBarButtonItem(customView: button)

        if badge > 0 {
            let badgeView = BadgeSwift()
            badgeView.frame = CGRect(x: item.customView!.width - 8.0, y: -4.0, width: 16.0, height: 16.0)
            badgeView.font = UIFont(name: "Exo2-Bold", size: 12.0)!
            badgeView.insets = CGSize(width: 4.0, height: 4.0)
            badgeView.badgeColor = .red
            badgeView.borderWidth = 0.2
            badgeView.borderColor = .black
            badgeView.shadowOpacityBadge = 0.5
            badgeView.shadowOffsetBadge = CGSize(width: 0.0, height: 0.0)
            badgeView.shadowRadiusBadge = 1.0
            badgeView.shadowColorBadge = .black
            badgeView.shadowOpacityBadge = 0
            badgeView.textColor = .white
            badgeView.text = "\(badge)"

            item.customView!.addSubview(badgeView)
        }

        return item
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)

        isSelected = true

        if shouldPassTouchToSuperview(touches.first!) {
            superview!.touchesBegan(touches, with: event)
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)

        isSelected = false

        if shouldPassTouchToSuperview(touches.first!) {
            superview!.touchesEnded(touches, with: event)
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)

        isSelected = false

        if shouldPassTouchToSuperview(touches.first!) {
            superview!.touchesCancelled(touches, with: event)
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)

        if shouldPassTouchToSuperview(touches.first!) {
            superview!.touchesMoved(touches, with: event)
        }
    }

    private func shouldPassTouchToSuperview(_ touch: UITouch) -> Bool {
        return false
    }
}
