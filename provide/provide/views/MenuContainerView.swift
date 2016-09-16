//
//  MenuContainerView.swift
//  provide
//
//  Created by Kyle Thomas on 7/25/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit
import KTSwiftExtensions

class MenuContainerView: UIView {

    fileprivate var backgroundView: UIView!

    fileprivate var menuViewController: MenuViewController!

    fileprivate var touchesBeganTimestamp: Date!

    fileprivate var menuViewControllerFrame: CGRect {
        var width = frame.width
        if isIPad() {
            width = width * 0.5
        } else {
            width = min(274.0, width * 0.66)
        }

        return CGRect(x: menuViewFrameOffsetX,
                      y: 0.0,
                      width: width,
                      height: frame.height)
    }

    fileprivate var menuViewFrameOffsetX: CGFloat {
        return frame.width * (1.0 - ((isIPad() ? 0.5 : 0.66) + exposedMenuViewPercentage))
    }

    fileprivate var exposedMenuViewPercentage: CGFloat {
        return 0.025
    }

    fileprivate var closedMenuOffsetX: CGFloat {
        return (frame.width * (1.0 - exposedMenuViewPercentage)) * -1.0
    }

    fileprivate var gestureInProgress: Bool {
        return touchesBeganTimestamp != nil
    }

    fileprivate var isOpen: Bool {
        return frame.origin.x > closedMenuOffsetX
    }

    fileprivate var targetView: UIView! {
        if let targetView = UIApplication.shared.keyWindow {
            return targetView
        }
        return nil
    }

    fileprivate func teardown() {
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

        NotificationCenter.default.removeObserver(self)
    }

    func redraw(_ size: CGSize) {
        let open = isOpen
        let delegate = menuViewController.delegate
        setupMenuViewController(delegate!)
        if open {
            openMenu()
        }
    }

    func setupMenuViewController(_ delegate: MenuViewControllerDelegate) {
        teardown()

        accessibilityIdentifier = "MenuContainerView"

        NotificationCenter.default.addObserver(self, selector: #selector(MenuContainerView.openMenu), name: "MenuContainerShouldOpen")
        NotificationCenter.default.addObserver(self, selector: #selector(MenuContainerView.closeMenu), name: "MenuContainerShouldReset")

        addDropShadow(CGSize(width: 2.5, height: 2.0), radius: 10.0, opacity: 0.75)
        layer.shadowOpacity = 0.0

        if let targetView = targetView {
            backgroundView = UIView(frame: targetView.bounds)
            backgroundView.frame.size.height = max(targetView.bounds.height, targetView.bounds.width)
            backgroundView.frame.size.width = max(targetView.bounds.height, targetView.bounds.width)
            backgroundView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(MenuContainerView.closeMenu)))
            backgroundView.backgroundColor = UIColor.black
            backgroundView.alpha = 0.0

            frame = CGRect(x: 0.0,
                           y: 0.0,
                           width: targetView.bounds.width,
                           height: targetView.bounds.height)
            frame.origin.x = closedMenuOffsetX

            targetView.addSubview(backgroundView)
            targetView.bringSubview(toFront: backgroundView)

            menuViewController = UIStoryboard("Main").instantiateViewController(withIdentifier: "MenuViewController") as! MenuViewController
            menuViewController.delegate = delegate
            menuViewController.view.frame = menuViewControllerFrame
            addSubview(menuViewController.view)
            bringSubview(toFront: menuViewController.view)

            targetView.addSubview(self)
            targetView.bringSubview(toFront: self)
        }
    }

    deinit {
        teardown()

        NotificationCenter.default.removeObserver(self)
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if let navigationController = menuViewController.delegate?.navigationControllerForMenuViewController(menuViewController) {
            let navbarHeight = navigationController.navigationBar.frame.height + UIApplication.shared.statusBarFrame.height
            if point.y <= navbarHeight {
                return menuViewController.view.point(inside: point, with: event)
            }
        }

        return super.point(inside: point, with: event)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)

        touchesBeganTimestamp = Date()
        applyTouches(touches)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)

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

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)

        touchesBeganTimestamp = nil
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)

        if let touchesBeganTimestamp = touchesBeganTimestamp {
            if Date().timeIntervalSince(touchesBeganTimestamp) < 0.1 {
                var xOffset: CGFloat = 0.0
                for touch in touches {
                    xOffset = touch.location(in: nil).x - touch.previousLocation(in: nil).x
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

    fileprivate func applyTouches(_ touches: Set<NSObject>) {
        for touch in touches {
            dragMenu(touch as! UITouch)
        }
    }

    fileprivate func dragMenu(_ touch: UITouch) {
        let xOffset = touch.location(in: nil).x - touch.previousLocation(in: nil).x
        let x = frame.origin.x + xOffset
        dragMenu(x)
    }

    fileprivate func dragMenu(_ x: CGFloat) {
        let percentage = 1.0 + (x / frame.width)
        layer.shadowOpacity = percentage == exposedMenuViewPercentage ? 0.0 : (Float(percentage - exposedMenuViewPercentage) * 2.0)

        if x > (menuViewFrameOffsetX * -1.0) {
            return
        }

        backgroundView.superview!.bringSubview(toFront: backgroundView)
        superview?.bringSubview(toFront: self)

        UIView.animate(withDuration: 0.1, delay: 0.0, options: UIViewAnimationOptions(),
            animations: {
                self.frame.origin.x = x
                self.backgroundView.alpha = 0.75 * percentage
            },
            completion: { complete in
                if !self.gestureInProgress {
                    UIApplication.shared.setStatusBarHidden(self.isOpen, with: .slide)
                }

                if !self.isOpen {
                    self.backgroundView.superview!.sendSubview(toBack: self.backgroundView)
                }
            }
        )
    }
}
