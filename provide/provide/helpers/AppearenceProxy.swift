//
//  AppearenceProxy.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit

class AppearenceProxy {

    class func setup() {
        UINavigationBar.appearance().setBackgroundImage(UIImage(), for: .default)
        UINavigationBar.appearance().backgroundColor = Color.applicationDefaultNavigationBarBackgroundColor()
        UINavigationBar.appearance().tintColor = nil
        UINavigationBar.appearance().titleTextAttributes = navBarTitleTextAttributes()

        UIBarButtonItem.appearance().tintColor = defaultBarTintColor()
        UIBarButtonItem.appearance().setTitleTextAttributes(barButtonItemTitleTextAttributes(), for: UIControlState())

        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UIToolbar.self]).tintColor = UIColor.white
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UIToolbar.self]).setTitleTextAttributes(whiteButtonItemTitleTextAttributes(), for: UIControlState())

        UITabBar.appearance().tintColor = defaultBarTintColor()
        UITabBarItem.appearance().setTitleTextAttributes(barButtonItemTitleTextAttributes(), for: UIControlState())

        UIToolbar.appearance().tintColor = defaultBarTintColor()
    }

    class func defaultBarTintColor() -> UIColor {
        return Color.applicationDefaultBarTintColor()
    }

    class func navBarTitleTextAttributes() -> [String : AnyObject] {
        return [
            NSFontAttributeName : UIFont(name: "Exo2-Light", size: 20)!,
            NSForegroundColorAttributeName : Color.darkBlueBackground(),
        ]
    }

    class func inProgressBarButtonItemTitleTextAttributes() -> [String : AnyObject] {
        return [
            NSFontAttributeName : UIFont(name: "Exo2-Bold", size: 14)!,
            NSForegroundColorAttributeName : Color.inProgressStatusColor(),
        ]
    }

    class func cancelBarButtonItemTitleTextAttributes() -> [String : AnyObject] {
        return [
            NSFontAttributeName : UIFont(name: "Exo2-Light", size: 14)!,
            NSForegroundColorAttributeName : Color.canceledStatusColor(),
        ]
    }

    class func whiteButtonItemTitleTextAttributes() -> [String : AnyObject] {
        return [
            NSFontAttributeName : UIFont(name: "Exo2-Light", size: 14)!,
            NSForegroundColorAttributeName : UIColor.white,
        ]
    }

    class func barButtonItemTitleTextAttributes() -> [String : AnyObject] {
        return [
            NSFontAttributeName : UIFont(name: "Exo2-Light", size: 14)!,
            NSForegroundColorAttributeName : Color.darkBlueBackground(),
        ]
    }

    class func selectedButtonItemTitleTextAttributes() -> [String : AnyObject] {
        return [
            NSFontAttributeName : UIFont(name: "Exo2-Bold", size: 14)!,
            NSForegroundColorAttributeName : Color.darkBlueBackground(),
        ]
    }

    class func barButtonItemDisabledTitleTextAttributes() -> [String : AnyObject] {
        return [
            NSFontAttributeName : UIFont(name: "Exo2-Light", size: 14)!,
            NSForegroundColorAttributeName : UIColor.darkGray,
        ]
    }
}

func addHexagonalOutline(to view: UIView, borderWidth: CGFloat = 1, cornerLength: CGFloat) {
    // Remove outline view layers if previously added (in the case of cell reuse)
    for layer in view.layer.sublayers ?? [] {
        if layer is CAShapeLayer {
            layer.removeFromSuperlayer()
        }
    }

    // Bubble Styling
    let halfLineWidth = borderWidth / 2

    // Mask layer
    let maskLayer = CAShapeLayer()
    maskLayer.lineWidth = borderWidth
    maskLayer.lineJoin = kCALineJoinMiter

    // Mask path
    let width = view.frame.width
    let height = view.frame.height
    let maskPath = UIBezierPath()
    maskPath.move(to: CGPoint(x: cornerLength + halfLineWidth, y: halfLineWidth))
    maskPath.addLine(to: CGPoint(x: width - cornerLength - halfLineWidth, y: halfLineWidth))
    maskPath.addLine(to: CGPoint(x: width - halfLineWidth, y: cornerLength + halfLineWidth))
    maskPath.addLine(to: CGPoint(x: width - halfLineWidth, y: height - cornerLength - halfLineWidth))
    maskPath.addLine(to: CGPoint(x: width - cornerLength - halfLineWidth, y: height - halfLineWidth))
    maskPath.addLine(to: CGPoint(x: cornerLength + halfLineWidth, y: height - halfLineWidth))
    maskPath.addLine(to: CGPoint(x: halfLineWidth, y: height - cornerLength - halfLineWidth))
    maskPath.addLine(to: CGPoint(x: halfLineWidth, y: cornerLength + halfLineWidth))
    maskPath.close()

    maskLayer.path = maskPath.cgPath
    view.layer.addSublayer(maskLayer)

    // Outline layer
    let outlineLayer = CAShapeLayer()
    view.layer.addSublayer(outlineLayer)
    outlineLayer.lineWidth = borderWidth
    outlineLayer.lineJoin = kCALineJoinMiter
    outlineLayer.strokeColor = UIColor.white.cgColor
    outlineLayer.fillColor = UIColor.clear.cgColor

    // Outline path
    let outlinePath = UIBezierPath(cgPath: maskPath.cgPath)
    outlineLayer.path = outlinePath.cgPath
    view.layer.mask = maskLayer
}
