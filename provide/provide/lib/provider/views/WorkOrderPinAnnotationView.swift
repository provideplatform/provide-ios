//
//  WorkOrderPinAnnotationView.swift
//  provide
//
//  Created by Kyle Thomas on 7/31/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

class WorkOrderPinAnnotationView: MKAnnotationView {

    private var rect: CGRect {
        return CGRect(x: 0.0, y: 0.0, width: 50.0, height: 50.0)
    }

    private var imageView: UIImageView {
        return UIImageView(image: UIImage("map-pin")!.resize(rect))
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = UIColor.clearColor()
        addSubview(imageView)

        centerOffset = CGPointMake(0, (rect.height / 2.0) * -1.0);
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
