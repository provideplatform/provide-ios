//
//  JobTableViewCell.swift
//  provide
//
//  Created by Kyle Thomas on 11/17/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

class JobTableViewCell: UITableViewCell {

    @IBOutlet weak var containerView: UIView!
    @IBOutlet private weak var backgroundContainerView: UIView!

    @IBOutlet private weak var nameLabel: UILabel!

    var job: Job! {
        didSet {
            if let job = job {
                nameLabel?.text = job.name
                nameLabel?.sizeToFit()
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        nameLabel?.text = ""
    }

    func dismiss() {
        UIView.animateWithDuration(0.3, delay: 0.1, options: .CurveEaseOut,
            animations: { [weak self] in
                if let s = self {
                    s.frame.origin.x = s.frame.size.width * -2.0
                }
            },
            completion: { complete in

            }
        )
    }

    func reset() {
        UIView.animateWithDuration(0.2, delay: 0.0, options: .CurveEaseOut,
            animations: { [weak self] in
                if let s = self {
                    s.frame.origin.x = 0.0
                    s.containerView.frame.origin.x = 0.0
                    s.containerView.backgroundColor = s.containerView.backgroundColor?.colorWithAlphaComponent(0.0)
                }
            },
            completion: { [weak self] complete in
                if let s = self {
                    if s.selected && s.highlighted {
                        s.containerView.backgroundColor = UIColor.whiteColor()
                    }
                }
            }
        )

    }
}
