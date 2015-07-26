//
//  UIViewExtensions.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

extension UIView {

    func enableTapToDismissKeyboard() {
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: "endEditing:"))
    }

    func roundCorners(radius: CGFloat) {
        layer.cornerRadius = radius
    }

    func addBorder(width: CGFloat, color: UIColor) {
        layer.borderColor = color.CGColor
        layer.borderWidth = width
    }

    func addDropShadow() {
        layer.shadowColor = UIColor.blackColor().CGColor
        layer.shadowOpacity = 0.75
        layer.shadowRadius = 2.0
        layer.shadowOffset = CGSizeMake(1.0, 2.0)
    }

    func addDropShadow(size: CGSize, radius: CGFloat, opacity: CGFloat) {
        layer.shadowColor = UIColor.blackColor().CGColor
        layer.shadowOpacity = Float(opacity)
        layer.shadowRadius = radius
        layer.shadowOffset = size
        //layer.shadowPath = UIBezierPath(rect:layer.bounds).CGPath
    }

    func addGradient(startColor: UIColor, endColor: UIColor, horizontal: Bool = false) {
        var gradient = CAGradientLayer()
        gradient.frame = bounds
        gradient.colors = [startColor.CGColor, endColor.CGColor]

        if horizontal {
            gradient.startPoint = CGPointMake(0.0, 0.5)
            gradient.endPoint = CGPointMake(1.0, 0.5)
        }

        layer.insertSublayer(gradient, atIndex: 0)
    }

    func makeCircular() {
        layer.cornerRadius = frame.width / 2
        clipsToBounds = true
    }
}
