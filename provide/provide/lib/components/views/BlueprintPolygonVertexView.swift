//
//  BlueprintPolygonVertexView.swift
//  provide
//
//  Created by Kyle Thomas on 11/10/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

protocol BlueprintPolygonVertexViewDelegate: NSObjectProtocol {
    func blueprintPolygonVertexViewShouldReceiveTouch(view: BlueprintPolygonVertexView) -> Bool
    func blueprintPolygonVertexViewShouldRedrawVertices(view: BlueprintPolygonVertexView)
    func blueprintPolygonVertexViewTapped(view: BlueprintPolygonVertexView)
}

class BlueprintPolygonVertexView: UIView, UIGestureRecognizerDelegate {

    weak var delegate: BlueprintPolygonVertexViewDelegate!

    var image: UIImage?

    private var blueprintPolygonVertexViewGestureRecognizer: BlueprintPolygonVertexViewGestureRecognizer!
    private var tapGestureRecognizer: UITapGestureRecognizer!

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
        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: "vertexTapped:")
        tapGestureRecognizer.delegate = self
        addGestureRecognizer(tapGestureRecognizer)

        blueprintPolygonVertexViewGestureRecognizer = BlueprintPolygonVertexViewGestureRecognizer(target: self, action: "vertexMoved:")
        blueprintPolygonVertexViewGestureRecognizer.delegate = self
        addGestureRecognizer(blueprintPolygonVertexViewGestureRecognizer)
    }

    func vertexMoved(gestureRecognizer: UIGestureRecognizer) {
        delegate?.blueprintPolygonVertexViewShouldRedrawVertices(self)
    }

    func vertexTapped(gestureRecognizer: UIGestureRecognizer) {
        delegate?.blueprintPolygonVertexViewTapped(self)
    }

    // MARK: UIGestureRecognizerDelegate

    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        if let delegate = delegate {
            return delegate.blueprintPolygonVertexViewShouldReceiveTouch(self)
        }
        return true
    }

    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return gestureRecognizer == self.blueprintPolygonVertexViewGestureRecognizer && otherGestureRecognizer == self.tapGestureRecognizer
            || gestureRecognizer == self.tapGestureRecognizer && otherGestureRecognizer == self.blueprintPolygonVertexViewGestureRecognizer
    }
}
