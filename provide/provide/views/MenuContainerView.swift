//
//  MenuContainerView.swift
//  provide
//
//  Created by Kyle Thomas on 7/25/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

class MenuContainerView: UIView {

    private var backgroundView: UIView!

    private var menuViewController: MenuViewController!

    private var menuViewControllerFrame: CGRect {
        return CGRect(x: menuViewFrameOffsetX,
                      y: 0.0,
                      width: bounds.width * 0.66,
                      height: bounds.height)
    }

    private var menuViewFrameOffsetX: CGFloat {
        return bounds.width * 0.25
    }

    private var exposedMenuViewPercentage: CGFloat {
        return 0.025
    }

    private var closedMenuOffsetX: CGFloat {
        return (frame.width * (1.0 - exposedMenuViewPercentage)) * -1.0
    }

    private var isOpen: Bool {
        return frame.origin.x > closedMenuOffsetX
    }

    func setupMenuViewController(delegate: MenuViewControllerDelegate) {
        if let superview = superview {
            removeFromSuperview()
        }

        if let backgroundView = backgroundView {
            backgroundView.removeFromSuperview()
            self.backgroundView = nil
        }

        if let menuViewController = menuViewController {
            menuViewController.view.removeFromSuperview()
            self.menuViewController = nil
        }

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "openMenu", name: "MenuContainerShouldOpen")
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "closeMenu", name: "MenuContainerShouldReset")

        addDropShadow(CGSize(width: 2.5, height: 2.0), radius: 10.0, opacity: 0.75)

        if let targetView = UIApplication.sharedApplication().keyWindow {
            backgroundView = UIView(frame: targetView.bounds)
            backgroundView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "closeMenu"))
            backgroundView.backgroundColor = UIColor.blackColor()
            backgroundView.alpha = 0.0

            menuViewController = UIStoryboard("Main").instantiateViewControllerWithIdentifier("MenuViewController") as! MenuViewController
            menuViewController.delegate = delegate
            menuViewController.view.frame = menuViewControllerFrame
            addSubview(menuViewController.view)
            bringSubviewToFront(menuViewController.view)

            frame = CGRect(x: 0.0,
                           y: 0.0,
                           width: targetView.bounds.width,
                           height: targetView.bounds.height)
            frame.origin.x = closedMenuOffsetX

            targetView.addSubview(backgroundView)
            targetView.bringSubviewToFront(backgroundView)

            targetView.addSubview(self)
            targetView.bringSubviewToFront(self)
        }
    }

    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        super.touchesBegan(touches, withEvent: event)

        for touch in touches {
            dragMenu(touch as! UITouch)
        }
    }

    override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
        super.touchesEnded(touches, withEvent: event)

        let percentage = 1.0 + ((frame.origin.x + menuViewFrameOffsetX) / menuViewControllerFrame.width)
        if percentage > 0.5 {
            openMenu()
        } else {
            closeMenu()
        }
    }

    override func touchesCancelled(touches: Set<NSObject>!, withEvent event: UIEvent!) {
        super.touchesCancelled(touches, withEvent: event)
    }

    override func touchesMoved(touches: Set<NSObject>, withEvent event: UIEvent) {
        super.touchesMoved(touches, withEvent: event)

        for touch in touches {
            dragMenu(touch as! UITouch)
        }
    }

    func openMenu() {
        dragMenu(0.0 - menuViewFrameOffsetX)
    }

    func closeMenu() {
        dragMenu(closedMenuOffsetX)
    }

    private func dragMenu(touch: UITouch) {
        let xOffset = touch.locationInView(nil).x - touch.previousLocationInView(nil).x
        let x = frame.origin.x + xOffset
        dragMenu(x)
    }

    private func dragMenu(x: CGFloat) {
        let percentage = 1.0 + (x / frame.width)

        if x > (menuViewFrameOffsetX * -1.0) {
            return
        }

        backgroundView.superview!.bringSubviewToFront(backgroundView)
        superview!.bringSubviewToFront(self)

        UIView.animateWithDuration(0.1, delay: 0.0, options: .CurveEaseInOut,
            animations: {
                self.frame.origin.x = x
                self.backgroundView.alpha = 0.75 * percentage
            },
            completion: { complete in
                UIApplication.sharedApplication().setStatusBarHidden(self.isOpen, withAnimation: .Slide)

                if !self.isOpen {
                    self.backgroundView.superview!.sendSubviewToBack(self.backgroundView)
                }
            }
        )
    }
}
