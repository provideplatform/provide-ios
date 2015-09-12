//
//  CastingDemandRecommendationContainerView.swift
//  startrack
//
//  Created by Kyle Thomas on 9/12/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

protocol CastingDemandRecommendationContainerViewDelegate {
    func providerForCastingDemandRecommendationContainerView(view: CastingDemandRecommendationContainerView) -> Provider
    func castingDemandRecommendationContainerView(view: CastingDemandRecommendationContainerView, didRejectRecommendedProvider: Provider)
    func castingDemandRecommendationContainerView(view: CastingDemandRecommendationContainerView, didApproveRecommendedProvider: Provider)
}

class CastingDemandRecommendationContainerView: UIView {

    var delegate: CastingDemandRecommendationContainerViewDelegate! {
        didSet {
            if let profileImageUrl = provider.profileImageUrl {
                profileImageView.contentMode = .ScaleAspectFit
                profileImageView.sd_setImageWithURL(profileImageUrl) { image, error, imageCacheType, url in
                    self.bringSubviewToFront(self.profileImageView)
                    self.profileImageView.alpha = 1.0
                }
            } else {
                profileImageView.image = nil
                profileImageView.alpha = 0.0
            }

            nameLabel.text = "\(provider.contact.name), \(provider.age)"
            bioLabel.text = "Male, 6'3\", 210 lbs"
            affiliationsLabel.text = ""
        }
    }

    @IBOutlet private weak var profileImageView: UIImageView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var bioLabel: UILabel!
    @IBOutlet private weak var affiliationsLabel: UILabel!

    private var provider: Provider! {
        return delegate?.providerForCastingDemandRecommendationContainerView(self)
    }

    private var touchesBeganTimestamp: NSDate!
    private var initialCenter: CGPoint!

    private let swipeLeftThreshold = 0.35
    private let swipeRightThreshold = 0.65

    private var gestureInProgress: Bool {
        return touchesBeganTimestamp != nil
    }

    private var shouldCompleteSwipeLeft: Bool {
        let percentage = Double(center.x / superview!.frame.width)
        return percentage <= swipeLeftThreshold
    }

    private var shouldCompleteSwipeRight: Bool {
        let percentage = Double(center.x / superview!.frame.width)
        return percentage >= swipeRightThreshold
    }

    private var shouldCompleteSwipe: Bool {
        return shouldCompleteSwipeLeft || shouldCompleteSwipeRight
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        addBorder(0.75, color: UIColor.lightGrayColor())
        roundCorners(5.0)
    }

    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesBegan(touches, withEvent: event)

        if initialCenter == nil {
            initialCenter = center
        }

        touchesBeganTimestamp = NSDate()
        applyTouches(touches)
    }

    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesEnded(touches, withEvent: event)

        if let _ = touchesBeganTimestamp {
            if !shouldCompleteSwipe {
                UIView.animateWithDuration(0.15, delay: 0.1, options: .CurveEaseOut,
                    animations: {
                        self.center = self.initialCenter
                    },
                    completion: { complete in

                    }
                )
            } else {
                //let lastTouch = Array(touches).last! as UITouch
                //let angle = Double(atan2(lastTouch.previousLocationInView(nil).y - lastTouch.locationInView(nil).y, lastTouch.locationInView(nil).x - lastTouch.previousLocationInView(nil).x)) * (180 / M_PI)

                if shouldCompleteSwipeLeft {
                    //dismiss(CGFloat(angle))
                    reject()
                } else if shouldCompleteSwipeRight {
                    //dismiss(CGFloat(angle))
                    approve()
                }
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
                applyTouches(touches)

//                var xOffset: CGFloat = 0.0
//                for touch in touches {
//                    xOffset = touch.locationInView(nil).x - touch.previousLocationInView(nil).x
//                }

                //let lastTouch = Array(touches).last! as UITouch
                //let angle = Double(atan2(lastTouch.previousLocationInView(nil).y - lastTouch.locationInView(nil).y, lastTouch.locationInView(nil).x - lastTouch.previousLocationInView(nil).x)) * (180 / M_PI)

//                if xOffset > 25.0 {
//                    dismiss(CGFloat(angle))
//                    approve()
//                } else if xOffset < -25.0 {
//                    dismiss(CGFloat(angle))
//                    reject()
//                }
            } else {
                applyTouches(touches)
            }
        }
    }

//    private func dismiss(angle: CGFloat) {
//        UIView.animateWithDuration(0.15, delay: 0.0, options: .CurveLinear,
//            animations: {
//                self.frame.origin.x += 250.0 * cos(angle)
//                self.frame.origin.y += 250.0 * sin(angle)
//            },
//            completion: { complete in
//                dispatch_after_delay(1.0) {
//                    self.center = self.initialCenter
//                }
//            }
//        )
//    }

    private func reject() {
        UIView.animateWithDuration(0.15, delay: 0.0, options: .CurveLinear,
            animations: {
                self.frame.origin.x += self.frame.width * -1.0
            },
            completion: { complete in
                self.delegate?.castingDemandRecommendationContainerView(self, didRejectRecommendedProvider: provider)
            }
        )
    }

    private func approve() {
        UIView.animateWithDuration(0.15, delay: 0.0, options: .CurveLinear,
            animations: {
                self.frame.origin.x += self.frame.width
            },
            completion: { complete in
                self.delegate?.castingDemandRecommendationContainerView(self, didApproveRecommendedProvider: provider)
            }
        )
    }

    private func applyTouches(touches: Set<UITouch>) {
        for touch in touches {
            let xOffset = touch.locationInView(nil).x - touch.previousLocationInView(nil).x
            let yOffset = touch.locationInView(nil).y - touch.previousLocationInView(nil).y
            let x = frame.origin.x + xOffset
            let y = frame.origin.y + yOffset
            dragContainer(x, y: y)
        }
    }

    private func dragContainer(x: CGFloat, y: CGFloat) {
        //let percentage = (x / frame.width)
        let percentage = Double(center.x / superview!.frame.width)



        if percentage <= swipeLeftThreshold {
            // swiped left
        } else if percentage >= swipeRightThreshold {
            // swiped right
        }

        //backgroundView.superview!.bringSubviewToFront(backgroundView)
        superview!.bringSubviewToFront(self)

        UIView.animateWithDuration(0.0, delay: 0.0, options: .CurveLinear,
            animations: {
                self.frame.origin.x = x
                self.frame.origin.y = y

                //self.backgroundView.alpha = 0.75 * percentage
            },
            completion: { complete in
//                if !self.gestureInProgress {
//                    UIApplication.sharedApplication().setStatusBarHidden(self.isOpen, withAnimation: .Slide)
//                }

                //if !self.isOpen {
                //    self.backgroundView.superview!.sendSubviewToBack(self.backgroundView)
                //}
            }
        )
    }
}
