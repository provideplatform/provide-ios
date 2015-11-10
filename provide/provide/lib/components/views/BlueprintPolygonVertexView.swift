//
//  BlueprintPolygonVertexView.swift
//  provide
//
//  Created by Kyle Thomas on 11/10/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

protocol BlueprintPolygonVertexViewDelegate {
    func blueprintPolygonVertexViewShouldRedrawVertices(view: BlueprintPolygonVertexView)
}

class BlueprintPolygonVertexView: UIView, UIGestureRecognizerDelegate {

    var delegate: BlueprintPolygonVertexViewDelegate!

    var image: UIImage?

    init(image: UIImage) {
        super.init(frame: CGRect(x: 0.0,
                                 y: 0.0,
                                 width: image.size.width,
                                 height: image.size.height))

        self.image = image

        self.backgroundColor = UIColor(patternImage: image)
        self.userInteractionEnabled = true

        setupGestureRecognizers()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupGestureRecognizers() {
        let gestureRecognizer = BlueprintPolygonVertexViewGestureRecognizer(target: self, action: "vertexMoved:")
        gestureRecognizer.delegate = self
        addGestureRecognizer(gestureRecognizer)
    }

    func vertexMoved(gestureRecognizer: UIGestureRecognizer) {
        delegate?.blueprintPolygonVertexViewShouldRedrawVertices(self)
    }
    
    // MARK: UIGestureRecognizerDelegate

    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        return true
    }

    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
}
