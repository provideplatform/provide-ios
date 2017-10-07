//
//  WorkOrderPinAnnotationView.swift
//  provide
//
//  Created by Kyle Thomas on 7/31/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit

class WorkOrderPinAnnotationView: MKAnnotationView {

    private var rect: CGRect {
        return CGRect(x: 0.0, y: 0.0, width: 50.0, height: 50.0)
    }

    private var imageView: UIImageView {
        let pin = #imageLiteral(resourceName: "provide-pin")
        return UIImageView(image: pin.resize(rect))
    }

    init(frame: CGRect) {
        super.init(annotation: nil, reuseIdentifier: nil)

        backgroundColor = .clear
        addSubview(imageView)

        centerOffset = CGPoint(x: 0, y: (rect.height / 2.0) * -1.0)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
