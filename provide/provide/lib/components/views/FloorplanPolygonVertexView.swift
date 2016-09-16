//
//  FloorplanPolygonVertexView.swift
//  provide
//
//  Created by Kyle Thomas on 11/10/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit

protocol FloorplanPolygonVertexViewDelegate: NSObjectProtocol {
    func floorplanPolygonVertexViewShouldReceiveTouch(_ view: FloorplanPolygonVertexView) -> Bool
    func floorplanPolygonVertexViewShouldRedrawVertices(_ view: FloorplanPolygonVertexView)
    func floorplanPolygonVertexViewTapped(_ view: FloorplanPolygonVertexView)
}

class FloorplanPolygonVertexView: UIView, UIGestureRecognizerDelegate {

    weak var delegate: FloorplanPolygonVertexViewDelegate!

    var image: UIImage?

    fileprivate var floorplanPolygonVertexViewGestureRecognizer: FloorplanPolygonVertexViewGestureRecognizer!
    fileprivate var tapGestureRecognizer: UITapGestureRecognizer!

    init(image: UIImage) {
        super.init(frame: CGRect(x: 0.0,
                                 y: 0.0,
                                 width: image.size.width,
                                 height: image.size.height))

        self.image = image

        self.backgroundColor = UIColor(patternImage: image)
        self.isUserInteractionEnabled = true

        setupGestureRecognizers()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    fileprivate func setupGestureRecognizers() {
        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(FloorplanPolygonVertexView.vertexTapped(_:)))
        tapGestureRecognizer.delegate = self
        addGestureRecognizer(tapGestureRecognizer)

        floorplanPolygonVertexViewGestureRecognizer = FloorplanPolygonVertexViewGestureRecognizer(target: self, action: #selector(FloorplanPolygonVertexView.vertexMoved(_:)))
        floorplanPolygonVertexViewGestureRecognizer.delegate = self
        addGestureRecognizer(floorplanPolygonVertexViewGestureRecognizer)
    }

    func vertexMoved(_ gestureRecognizer: UIGestureRecognizer) {
        delegate?.floorplanPolygonVertexViewShouldRedrawVertices(self)
    }

    func vertexTapped(_ gestureRecognizer: UIGestureRecognizer) {
        delegate?.floorplanPolygonVertexViewTapped(self)
    }

    // MARK: UIGestureRecognizerDelegate

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if let delegate = delegate {
            return delegate.floorplanPolygonVertexViewShouldReceiveTouch(self)
        }
        return true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return gestureRecognizer == self.floorplanPolygonVertexViewGestureRecognizer && otherGestureRecognizer == self.tapGestureRecognizer
            || gestureRecognizer == self.tapGestureRecognizer && otherGestureRecognizer == self.floorplanPolygonVertexViewGestureRecognizer
    }
}
