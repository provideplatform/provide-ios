//
//  AnnotationView.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import MapKit

class AnnotationView: MKAnnotationView {

    var onConfirmationRequired: VoidBlock!
    var selectedBackgroundColor = UIColor.darkGray
    var selectableViews = [UIView]()
    var unselectedBackgroundColor = Color.darkBlueBackground()

    @IBOutlet weak var containerView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()

        canShowCallout = false
        isDraggable = false

        isOpaque = false
        backgroundColor = .clear
    }

    @objc private func gestureRecognized(_: UIGestureRecognizer) {
        log("recognized")
    }

    func attachGestureRecognizers() {
        let recognizer = GestureRecognizer(annotationView: self)
        containerView.addGestureRecognizer(recognizer)
    }

    private func _detatchGestureRecognizers() {
        for recognizer in containerView.gestureRecognizers ?? [] {
            containerView.removeGestureRecognizer(recognizer)
        }
    }

    private class GestureRecognizer: UIGestureRecognizer, UIGestureRecognizerDelegate {

        private weak var annotationView: AnnotationView!

        private var initialTouch: UITouch? {
            didSet {
                selected = initialTouch != nil
            }
        }

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

        init(annotationView: AnnotationView) {
            super.init(target: annotationView, action: #selector(gestureRecognized(_:)))
            self.annotationView = annotationView
            delegate = self
        }

        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
            initialTouch = touches.first
        }

        override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {

        }

        override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
            if selected {
                annotationView.onConfirmationRequired?()
            }

            initialTouch = nil
        }

        // MARK: UIGestureRecognizerDelegate

        @objc func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return true
        }

        @objc func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            return true
        }
    }
}
