//
//  AnnotationView.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import MapKit

class AnnotationView: MKAnnotationView {

    var onConfirmationRequired: VoidBlock!
    var selectedBackgroundColor = UIColor.darkGrayColor()
    var selectableViews = [UIView]()
    var unselectedBackgroundColor = Color.darkBlueBackground()

    @IBOutlet weak var containerView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()

        canShowCallout = false
        draggable = false

        opaque = false
        backgroundColor = UIColor.clearColor()
    }

    func gestureRecognized() {
        log("recognized")
    }

    func attachGestureRecognizers() {
        let recognizer = GestureRecognizer(annotationView: self)
        containerView.addGestureRecognizer(recognizer)
    }

    func removeGestureRecognizers() {
        for recognizer in containerView.gestureRecognizers ?? [] {
            containerView.removeGestureRecognizer(recognizer)
        }
    }

    private class GestureRecognizer: UIGestureRecognizer, UIGestureRecognizerDelegate {

        private weak var annotationView: AnnotationView!

        var selected: Bool = false {
            didSet {
                var color = annotationView.unselectedBackgroundColor
                if selected {
                    color = annotationView.selectedBackgroundColor
                }

                for view in annotationView.selectableViews {
                    view.backgroundColor = color
                }
            }
        }

        init(annotationView: AnnotationView!) {
            super.init(target: annotationView, action: "gestureRecognized")
            self.annotationView = annotationView
            delegate = self
        }

        override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent) {
            selected = true
        }

        override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent) {
            selected = false
        }

        override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent) {
            if selected {
                if let callback = annotationView.onConfirmationRequired {
                    callback()
                }
            }

            selected = false
        }

        // MARK: UIGestureRecognizerDelegate

        @objc func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return true
        }

        @objc func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
            return true
        }

    }
}
