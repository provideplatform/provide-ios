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

    private var touchesBeganTimestamp: NSDate!

    private var menuViewControllerFrame: CGRect {
        return CGRect(x: menuViewFrameOffsetX,
                      y: 0.0,
                      width: frame.width * (isIPad() ? 0.5 : 0.66),
                      height: frame.height)
    }

    private var menuViewFrameOffsetX: CGFloat {
        return bounds.width * (1.0 - ((isIPad() ? 0.5 : 0.66) + exposedMenuViewPercentage))
    }

    private var exposedMenuViewPercentage: CGFloat {
        return 0.05
    }

    private var closedMenuOffsetX: CGFloat {
        return (frame.width * (1.0 - exposedMenuViewPercentage)) * -1.0
    }

    private var gestureInProgress: Bool {
        return touchesBeganTimestamp != nil
    }

    private var isOpen: Bool {
        return frame.origin.x > closedMenuOffsetX
    }

    private func teardown() {
        if let _ = superview {
            removeFromSuperview()
        }

        if let backgroundView = backgroundView {
            backgroundView.removeFromSuperview()
            backgroundView.removeGestureRecognizers()
            self.backgroundView = nil
        }

        if let menuViewController = menuViewController {
            menuViewController.view.removeFromSuperview()
            self.menuViewController = nil
        }
    }

    func setupMenuViewController(delegate: MenuViewControllerDelegate) {
        teardown()

        accessibilityIdentifier = "MenuContainerView"

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "openMenu", name: "MenuContainerShouldOpen")
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "closeMenu", name: "MenuContainerShouldReset")

        addDropShadow(CGSize(width: 2.5, height: 2.0), radius: 10.0, opacity: 0.75)
        layer.shadowOpacity = 0.0

        if let targetView = UIApplication.sharedApplication().keyWindow {
            backgroundView = UIView(frame: targetView.bounds)
            backgroundView.frame.size.width = max(targetView.bounds.height, targetView.bounds.width)
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

    deinit {
        teardown()

        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
        if let navigationController = menuViewController.delegate?.navigationControllerForMenuViewController(menuViewController) {
            let navbarHeight = navigationController.navigationBar.frame.height + UIApplication.sharedApplication().statusBarFrame.height
            if point.y <= navbarHeight {
                return menuViewController.view.pointInside(point, withEvent: event)
            }
        }

        return super.pointInside(point, withEvent: event)
    }

    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesBegan(touches, withEvent: event)

        touchesBeganTimestamp = NSDate()
        applyTouches(touches)
    }

    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesEnded(touches, withEvent: event)

        if let _ = touchesBeganTimestamp {
            let percentage = 1.0 + ((frame.origin.x + menuViewFrameOffsetX) / menuViewControllerFrame.width)
            if percentage > 0.5 {
                openMenu()
            } else {
                closeMenu()
            }
        }

        touchesBeganTimestamp = nil
    }

    override func touchesCancelled(touches: Set<UITouch>!, withEvent event: UIEvent?) {
        super.touchesCancelled(touches, withEvent: event)

        touchesBeganTimestamp = nil
    }

    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesMoved(touches, withEvent: event)

        if let touchesBeganTimestamp = touchesBeganTimestamp {
            if NSDate().timeIntervalSinceDate(touchesBeganTimestamp) < 0.1 {
                var xOffset: CGFloat = 0.0
                for touch in touches {
                    xOffset = touch.locationInView(nil).x - touch.previousLocationInView(nil).x
                }

                if xOffset > 15.0 {
                    openMenu()
                } else if xOffset < -15.0 {
                    closeMenu()
                } else {
                    applyTouches(touches)
                }
            } else {
                applyTouches(touches)
            }
        }
    }

    func openMenu() {
        dragMenu(0.0 - menuViewFrameOffsetX)
    }

    func closeMenu() {
        dragMenu(closedMenuOffsetX)
    }

    private func applyTouches(touches: Set<NSObject>) {
        for touch in touches {
            dragMenu(touch as! UITouch)
        }
    }

    private func dragMenu(touch: UITouch) {
        let xOffset = touch.locationInView(nil).x - touch.previousLocationInView(nil).x
        let x = frame.origin.x + xOffset
        dragMenu(x)
    }

    private func dragMenu(x: CGFloat) {
        let percentage = 1.0 + (x / frame.width)
        layer.shadowOpacity = percentage == exposedMenuViewPercentage ? 0.0 : (Float(percentage - exposedMenuViewPercentage) * 2.0)

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
                if !self.gestureInProgress {
                    UIApplication.sharedApplication().setStatusBarHidden(self.isOpen, withAnimation: .Slide)
                }

                if !self.isOpen {
                    self.backgroundView.superview!.sendSubviewToBack(self.backgroundView)
                }
            }
        )
    }
}
